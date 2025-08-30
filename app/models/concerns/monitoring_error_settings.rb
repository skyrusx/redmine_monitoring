# frozen_string_literal: true

module MonitoringErrorSettings
  extend ActiveSupport::Concern
  include RedmineMonitoring::Constants

  class_methods do
    def max_errors
      fetch_setting('max_errors', DEFAULT_SETTINGS[:max_errors]) { |value| value.to_i if value.to_i.positive? }
    end

    def retention_days
      fetch_setting('retention_days', DEFAULT_SETTINGS[:retention_days]) do |value|
        value.to_i if value.to_i.positive?
      end
    end

    def log_levels
      fetch_setting('log_levels', DEFAULT_SETTINGS[:log_levels]) { |value| valid_log_levels(value) }
    end

    def enabled_formats
      fetch_setting('enabled_formats', DEFAULT_SETTINGS[:enabled_formats]) { |value| valid_log_levels(value) }
    end

    private

    def fetch_setting(key, fallback)
      return fallback unless Setting.respond_to?(:plugin_redmine_monitoring)

      value = Setting.plugin_redmine_monitoring[key]
      processed = block_given? ? yield(value) : value.presence
      processed || fallback
    rescue StandardError
      fallback
    end

    def valid_log_levels(value)
      (Array(value).map(&:to_s) & SEVERITIES).presence
    end
  end
end
