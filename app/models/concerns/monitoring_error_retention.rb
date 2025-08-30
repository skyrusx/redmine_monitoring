# frozen_string_literal: true

module MonitoringErrorRetention
  extend ActiveSupport::Concern
  include RedmineMonitoring::Constants

  def enforce_max_errors(mode: :boundary)
    case mode
    when :simple then enforce_with_simple_batch
    when :advisory then enforce_with_advisory_lock
    else enforce_with_boundary
    end
  end

  def enforce_retention(batch_size: DEFAULT_BATCH_SIZE)
    days = self.class.retention_days
    return if days <= 0

    cutoff_date = Time.current - days.days
    scope = self.class.where(self.class.arel_table[:created_at].lt(cutoff_date))

    loop do
      deleted = scope.limit(batch_size).delete_all
      break if deleted < batch_size
    end
  end

  private

  # Boundary + батчи (по умолчанию)
  def enforce_with_boundary
    boundary = boundary_record
    return unless boundary

    scope_for_boundary(boundary).in_batches(of: 1000, &:delete_all)
  end

  def boundary_record
    limit = self.class.max_errors
    return unless self.class.latest_order.offset(limit).limit(1).exists?

    self.class.latest_order.offset(limit - 1).select(:created_at, :id).first
  end

  def scope_for_boundary(boundary)
    arel = self.class.arel_table
    condition = arel[:created_at].lt(boundary.created_at)
                                 .or(
                                   arel[:created_at].eq(boundary.created_at)
                                                    .and(arel[:id].lt(boundary.id))
                                 )

    self.class.where(condition)
  end

  # Простой вариант, через pluck id (может грузить память)
  def enforce_with_simple_batch
    max_allowed = self.class.max_errors
    excess = self.class.count - max_allowed
    return if excess <= 0

    self.class.latest_order.offset(max_allowed).in_batches(of: [excess, DEFAULT_BATCH_SIZE].min, &:delete_all)
  end

  # С advisory lock (только для PostgreSQL)
  def enforce_with_advisory_lock
    record_id = id
    return unless record_id && (record_id % ADVISORY_LOCK_INTERVAL).zero?

    lock_key = Zlib.crc32("#{self.class.table_name}:enforce", 0)
    self.class.connection.execute("SELECT pg_advisory_lock(#{lock_key})")
    enforce_with_boundary
  ensure
    self.class.connection.execute("SELECT pg_advisory_unlock(#{lock_key})")
  end
end
