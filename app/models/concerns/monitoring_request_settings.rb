# frozen_string_literal: true

module MonitoringRequestSettings
  extend ActiveSupport::Concern
  include RedmineMonitoring::Constants

  class_methods do
    def max_records
      fetch_setting('metrics_max_records', DEFAULT_SETTINGS[:metrics_max_records]) do |value|
        value.to_i if value.to_i.positive?
      end
    end

    def retention_days
      fetch_setting('metrics_retention_days', DEFAULT_SETTINGS[:metrics_retention_days]) do |value|
        value.to_i if value.to_i.positive?
      end
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
  end
end
