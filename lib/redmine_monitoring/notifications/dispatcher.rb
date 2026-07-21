# frozen_string_literal: true

module RedmineMonitoring
  module Notifications
    class Dispatcher
      include RedmineMonitoring::Constants

      def call(error_id)
        settings = fetch_settings
        unless notifications_enabled?(settings)
          RedmineMonitoring::OperationalLogger.once(:notifications_disabled,
                                                    message: 'notifications disabled by settings')
          return
        end

        log_channel_diagnostics(settings)

        error = MonitoringError.find(error_id)
        return unless allowed?(error, settings)

        fingerprint = build_fingerprint(error)
        window_sec = grouping_seconds(settings)

        manager = AlertWindowManager.new(fingerprint, error, window_sec)
        alert_window = manager.upsert!

        return if suppressed?(alert_window, settings)
        return if throttled?(fingerprint, settings)

        Deliverer.new(alert_window, error, settings).deliver!
        manager.mark_notified!(alert: alert_window)
      rescue StandardError => e
        RedmineMonitoring::OperationalLogger.error("notification dispatcher failed: #{e.class}: #{e.message}")
      end

      private

      def fetch_settings
        Setting.plugin_redmine_monitoring || {}
      end

      def notifications_enabled?(settings)
        truthy?(settings['notify_enabled'])
      end

      def allowed?(error, settings)
        allowed_severity?(error, settings) && allowed_format?(error, settings)
      end

      def grouping_seconds(settings)
        settings.fetch('notify_grouping_window_sec', 300).to_i
      end

      def delivery_channels(settings)
        Array(settings['notify_channels']).map(&:to_s)
      end

      def log_channel_diagnostics(settings)
        channels = delivery_channels(settings)
        if channels.empty?
          RedmineMonitoring::OperationalLogger.once(:notifications_no_channels,
                                                    level: :warn,
                                                    message: 'notifications enabled but no channels configured')
        end

        log_email_diagnostics(settings, channels)
        log_telegram_diagnostics(settings, channels)
      end

      def log_email_diagnostics(settings, channels)
        return unless channels.include?('email')

        recipients = settings['notify_email_recipients'].to_s.split(/[\s,]+/).reject(&:blank?)
        return if recipients.any?

        RedmineMonitoring::OperationalLogger.once(:notifications_email_missing_recipients,
                                                  level: :warn,
                                                  message: 'email notifications enabled but recipients missing')
      end

      def log_telegram_diagnostics(settings, channels)
        return unless channels.include?('telegram')

        token = settings['notify_telegram_bot_token'].to_s
        chats = settings['notify_telegram_chat_ids'].to_s.split(/[\s,]+/).reject(&:blank?)
        return if token.present? && chats.any?

        RedmineMonitoring::OperationalLogger.once(:notifications_telegram_incomplete,
                                                  level: :warn,
                                                  message: 'telegram notifications enabled but token or chat ids missing')
      end

      def suppressed?(alert_window, settings)
        suppressed_by_window?(alert_window, delivery_channels(settings), grouping_seconds(settings))
      end

      def suppressed_by_window?(alert_window, delivery_channels, grouping_window_seconds)
        window_seconds = grouping_window_seconds.to_i
        return false if window_seconds <= 0

        cutoff_time = Time.current - window_seconds

        MonitoringAlertChannel.where(monitoring_alert_id: alert_window.id, channel: delivery_channels)
                              .exists?(['last_sent_at >= ?', cutoff_time])
      end

      def allowed_severity?(monitoring_error, settings)
        min_required_severity = (settings['notify_severity_min'] || 'error').to_s
        current_severity = monitoring_error&.severity.to_s

        current_index = SEVERITIES.index(current_severity) || SEVERITIES.index('error')
        minimum_index = SEVERITIES.index(min_required_severity) || SEVERITIES.index('error')

        current_index <= minimum_index
      end

      def allowed_format?(monitoring_error, settings)
        allowed = Array(settings['notify_formats']).map { |v| v.to_s.downcase }.reject(&:empty?)
        return true if allowed.empty? || allowed.include?('*')

        allowed.include?(monitoring_error.format.to_s.downcase)
      end

      def build_fingerprint(monitoring_error)
        RedmineMonitoring::Notifications::Fingerprint.build(monitoring_error)
      end

      def throttled?(fingerprint, settings)
        per_minute_limit = settings.fetch('notify_throttle_per_group_per_min', 5).to_i
        return false unless per_minute_limit.positive?

        if throttled_per_minute?(fingerprint, per_minute_limit)
          RedmineMonitoring::OperationalLogger.info("notification throttled per-minute fingerprint=#{fingerprint}")
          true
        else
          false
        end
      end

      def throttled_per_minute?(fingerprint, per_minute_limit)
        cache_key = minute_slot_key(fingerprint)
        current_count = cache_increment(cache_key, expires_in: 90) # ~1 минута с запасом
        current_count > per_minute_limit
      rescue StandardError => e
        RedmineMonitoring::OperationalLogger.warn("notification throttle cache failed: #{e.class} #{e.message}")
        false
      end

      def minute_slot_key(fingerprint)
        slot = Time.now.utc.strftime('%Y%m%d%H%M')
        "rm:notify:fingerprint:#{fingerprint}:min:#{slot}"
      end

      def cache_increment(key, options = {})
        cache = Rails.cache
        if cache.respond_to?(:increment)
          cache.write(key, 0, options) unless cache.exist?(key)
          cache.increment(key)
        else
          current = cache.read(key).to_i + 1
          cache.write(key, current, options)
          current
        end
      end

      def truthy?(value)
        ActiveModel::Type::Boolean.new.cast(value)
      end
    end
  end
end
