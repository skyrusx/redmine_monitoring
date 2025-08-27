require 'csv'

class MonitoringError < ActiveRecord::Base
  include RedmineMonitoring::Constants

  belongs_to :user, optional: true

  validates :error_class, presence: true
  validates :message, presence: true
  validates :severity, inclusion: { in: SEVERITIES }, allow_nil: true

  after_commit :enforce_max_errors, :enforce_retention, on: :create

  scope :latest_order, -> { order(created_at: :desc, id: :desc) }
  scope :by_error_class, ->(value) { where(error_class: value) if value.present? }
  scope :by_controller_name, ->(value) { where(controller_name: value) if value.present? }
  scope :by_action_name, ->(value) { where(action_name: value) if value.present? }
  scope :by_user, ->(value) { where(user_id: value) if value.present? }
  scope :by_status, ->(value) { where(status_code: value) if value.present? }
  scope :by_error_format, ->(value) { where(format: value) if value.present? }
  scope :by_env, ->(value) { where(env: value) if value.present? }
  scope :by_severity, ->(value) { where(severity: value) if value.present? }
  scope :by_message, ->(value) do
    if value.present?
      adapter = connection.adapter_name
      adapter =~ /PostgreSQL/i ? where("message ILIKE ?", "%#{value}%") : where("message LIKE ?", "%#{value}%")
    end
  end
  scope :created_from, ->(date) { where("created_at >= ?", date.to_date.beginning_of_day) if date.present? }
  scope :created_to, ->(date) { where("created_at <= ?", date.to_date.end_of_day) if date.present? }

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
    days = self.class.retention_days
    return if days <= 0

    cutoff_date = Time.current - days.days
    scope = self.class.where(self.class.arel_table[:created_at].lt(cutoff_date))

    loop do
      deleted = scope.limit(batch_size).delete_all
      break if deleted < batch_size
    end
  end

  def self.filter(params)
    all.by_error_class(params[:error_class])
       .by_controller_name(params[:controller_name])
       .by_action_name(params[:action_name])
       .by_user(params[:user_id])
       .by_status(params[:status_code])
       .by_error_format(params[:error_format])
       .by_env(params[:env])
       .by_message(params[:message])
       .created_from(params[:created_at_from])
       .created_to(params[:created_at_to])
       .by_severity(params[:severity])
  end

  def self.log_levels
    settings = Setting.respond_to?(:plugin_redmine_monitoring) ? Setting.plugin_redmine_monitoring : {}
    levels = Array(settings['log_levels']).map(&:to_s) & SEVERITIES
    levels.presence || %w[fatal error warning]
  rescue
    %w[fatal error warning]
  end

  def self.allow_severity?(severity)
    log_levels.include?(severity.to_s)
  end

  def self.severity_for(status_code, exception = nil)
    return 'fatal' if exception

    code = status_code.to_i
    return 'error' if code >= 500
    return 'warning' if code >= 400

    'info'
  end

  def self.enabled_formats
    settings = Setting.respond_to?(:plugin_redmine_monitoring) ? Setting.plugin_redmine_monitoring : {}
    list = Array(settings['enabled_formats']).map { |format| format.to_s.strip.upcase }.uniq
    list.presence || %w[HTML JSON]
  rescue
    %w[HTML JSON]
  end

  def self.allow_format?(format)
    enabled_formats.include?(format.to_s.strip.upcase)
  end

  private

  def enforce_with_boundary
    # Boundary + батчи (по умолчанию)
    limit = self.class.max_errors
    return unless self.class.latest_order.offset(limit).limit(1).exists?

    boundary = self.class.latest_order.offset(limit - 1).select(:created_at, :id).first
    return unless boundary

    scope = self.class.where(
      self.class.arel_table[:created_at].lt(boundary.created_at)
          .or(
            self.class.arel_table[:created_at].eq(boundary.created_at)
                .and(self.class.arel_table[:id].lt(boundary.id))
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
