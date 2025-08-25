class MonitoringError < ActiveRecord::Base
  belongs_to :user, optional: true

  validates :error_class, presence: true
  validates :message, presence: true

  after_commit :enforce_max_errors, :enforce_retention, on: :create

  scope :latest_order, -> { order(created_at: :desc, id: :desc) }

  USEFUL_HEADERS = %w[HTTP_USER_AGENT HTTP_REFERER HTTP_ACCEPT HTTP_ACCEPT_LANGUAGE HTTP_X_REQUESTED_WITH].freeze

  HTTP_STATUS_TEXT = {
    400 => "Bad Request",
    401 => "Unauthorized",
    403 => "Forbidden",
    404 => "Not Found",
    405 => "Method Not Allowed",
    408 => "Request Timeout",
    422 => "Unprocessable Entity",
    429 => "Too Many Requests",
    500 => "Internal Server Error",
    502 => "Bad Gateway",
    503 => "Service Unavailable",
    504 => "Gateway Timeout"
  }.freeze

  def self.max_errors
    plugin_settings = Setting.respond_to?(:plugin_redmine_monitoring) ? Setting.plugin_redmine_monitoring : {}
    configured_value = plugin_settings && plugin_settings['max_errors']

    max_errors = configured_value.to_i
    max_errors.positive? ? max_errors : 10_000
  rescue
    10_000
  end

  def enforce_max_errors(mode: :boundary)
    case mode
    when :boundary then enforce_with_boundary
    when :simple then enforce_with_simple_batch
    when :advisory then enforce_with_advisory_lock
    else enforce_with_boundary
    end
  end

  def self.retention_days
    plugin_settings = Setting.respond_to?(:plugin_redmine_monitoring) ? Setting.plugin_redmine_monitoring : {}
    configured_value = plugin_settings && plugin_settings['retention_days']

    value = configured_value.to_i
    value.positive? ? value : 90
  rescue
    90
  end

  def enforce_retention(batch_size: 1000)
    days = self.retention_days
    cutoff_date = Time.current - days.days

    scope = self.where(arel_table[:created_at].lt(cutoff_date))
    loop do
      deleted = scope.limit(batch_size).delete_all
      break if deleted < batch_size
    end
  end

  private

  def enforce_with_boundary
    # Boundary + батчи (по умолчанию)
    limit = self.max_errors
    return unless self.latest_order.offset(limit).limit(1).exists?

    boundary = self.latest_order.offset(limit - 1).select(:created_at, :id).first
    return unless boundary

    scope = self.where(
      self.arel_table[:created_at].lt(boundary.created_at)
          .or(
            self.arel_table[:created_at].eq(boundary.created_at)
                .and(self.arel_table[:id].lt(boundary.id))
          )
    )

    scope.in_batches(of: 1000) { |batch| batch.delete_all }
  end

  def enforce_with_simple_batch
    # Простой вариант, через pluck id (может грузить память)
    max_allowed = self.max_errors
    total_count = self.count
    excess = total_count - max_allowed
    return if excess <= 0

    batch_size = [excess, 1_000].min
    ids_to_delete = self.latest_order.offset(max_allowed).limit(batch_size).pluck(:id)
    self.where(id: ids_to_delete).delete_all if ids_to_delete.any?
  end

  def enforce_with_advisory_lock
    # С advisory lock (только для PostgreSQL)
    record_id = self.id
    return unless record_id && record_id % 20 == 0

    lock_key = Zlib.crc32("#{self.table_name}:enforce", 0)
    self.connection.execute("SELECT pg_advisory_lock(#{lock_key})")
    begin
      enforce_with_boundary
    ensure
      self.connection.execute("SELECT pg_advisory_unlock(#{lock_key})")
    end
  end
end
