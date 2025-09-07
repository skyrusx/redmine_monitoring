# frozen_string_literal: true

module MonitoringRequestRetention
  extend ActiveSupport::Concern
  include RedmineMonitoring::Constants

  included do
    include MonitoringRequestSettings
    after_commit :maintain, on: :create
  end

  def maintain
    return unless (id % MAINTAIN_EVERY_N_CREATES).zero?

    self.class.maintain!(batch_size: DEFAULT_BATCH_SIZE)
  end

  class_methods do
    def maintain!(batch_size: DEFAULT_BATCH_SIZE, lock_ttl: MAINTAIN_LOCK_TTL)
      with_maintenance_lock(ttl: lock_ttl) do
        {
          retention: enforce_retention(batch_size: batch_size),
          max_records: enforce_max_records(batch_size: batch_size)
        }
      end || { retention: 0, max_records: 0 }
    end

    private

    def with_maintenance_lock(key: 'rm:metrics:maintain:lock', ttl: MAINTAIN_LOCK_TTL)
      acquired = Rails.cache.write(key, CACHE_DAYS, expires_in: ttl, unless_exist: true)
      return false unless acquired

      begin
        yield
      ensure
        Rails.cache.delete(key)
      end
    end
  end

  class_methods do
    def enforce_retention(batch_size: DEFAULT_BATCH_SIZE)
      days = retention_days.to_i
      return 0 if days <= 0

      cutoff_time = Time.current - days.days
      deleted_total = 0

      loop do
        ids = where(arel_table[:created_at].lt(cutoff_time)).order(:created_at, :id).limit(batch_size).pluck(:id)
        break if ids.empty?

        deleted_total += where(id: ids).delete_all
      end

      deleted_total
    end

    def enforce_max_records(batch_size: DEFAULT_BATCH_SIZE)
      max = max_records.to_i
      return 0 if max <= 0

      overage = unscope(:order).count - max
      return 0 if overage <= 0

      deleted_total = 0
      while overage.positive?
        batch = [overage, batch_size].min
        ids = order(:created_at, :id).limit(batch).pluck(:id)
        break if ids.empty?

        deleted_total += where(id: ids).delete_all
        overage -= ids.size
      end

      deleted_total
    end
  end
end
