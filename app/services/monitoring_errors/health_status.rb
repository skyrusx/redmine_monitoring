# frozen_string_literal: true

module MonitoringErrors
  class HealthStatus
    include RedmineMonitoring::Constants

    attr_reader :settings_status, :counts, :latest, :notifications

    def initialize
      @settings_status = build_settings_status
      @counts = build_counts
      @latest = build_latest
      @notifications = build_notifications
    end

    private

    def build_settings_status
      {
        monitoring_enabled: boolean_setting('enabled'),
        metrics_enabled: boolean_setting('enable_metrics'),
        recommendations_enabled: boolean_setting('enable_recommendations'),
        bullet_available: bullet_available?,
        bullet_enabled: bullet_enabled?,
        notifications_enabled: boolean_setting('notify_enabled'),
        security_enabled: boolean_setting('security_enabled')
      }
    end

    def build_counts
      {
        errors: safe_count(MonitoringError),
        metrics: safe_count(MonitoringRequest),
        recommendations: safe_count(MonitoringRecommendation),
        alerts: safe_count(MonitoringAlert),
        security_scans: safe_count(MonitoringSecurityScan)
      }
    end

    def build_latest
      {
        error: latest_record(MonitoringError),
        metric: latest_record(MonitoringRequest),
        recommendation: latest_record(MonitoringRecommendation),
        alert_channel: latest_record(MonitoringAlertChannel),
        security_scan: latest_record(MonitoringSecurityScan)
      }
    end

    def build_notifications
      active_channels = array_setting('notify_channels')
      email_recipients = split_values(setting_value('notify_email_recipients'))
      telegram_chats = split_values(setting_value('notify_telegram_chat_ids'))
      last_channel = latest[:alert_channel]

      {
        active_channels: active_channels,
        email_configured: email_recipients.any?,
        email_recipients_count: email_recipients.size,
        telegram_configured: setting_value('notify_telegram_bot_token').to_s.present? && telegram_chats.any?,
        telegram_chat_ids_count: telegram_chats.size,
        last_status: last_channel&.status,
        last_error: last_channel&.last_error,
        last_sent_at: last_channel&.last_sent_at
      }
    end

    def safe_count(model)
      model.count
    rescue StandardError
      0
    end

    def latest_record(model)
      model.order(created_at: :desc, id: :desc).first
    rescue StandardError
      nil
    end

    def settings
      return {} unless Setting.respond_to?(:plugin_redmine_monitoring)

      Setting.plugin_redmine_monitoring || {}
    rescue StandardError
      {}
    end

    def setting_value(key)
      settings[key] || settings[key.to_sym]
    end

    def boolean_setting(key)
      value = setting_value(key)
      value = DEFAULT_SETTINGS[key.to_sym] if value.nil?
      ActiveModel::Type::Boolean.new.cast(value)
    rescue StandardError
      false
    end

    def array_setting(key)
      value = setting_value(key)
      value = DEFAULT_SETTINGS[key.to_sym] if value.nil?
      Array(value).map(&:to_s).reject(&:blank?)
    end

    def split_values(value)
      Array(value).flat_map { |item| item.to_s.split(/[\s,]+/) }.reject(&:blank?)
    end

    def bullet_available?
      RedmineMonitoring::BulletIntegration.send(:bullet_available?)
    rescue StandardError
      false
    end

    def bullet_enabled?
      RedmineMonitoring::BulletIntegration.enable?
    rescue StandardError
      false
    end
  end
end
