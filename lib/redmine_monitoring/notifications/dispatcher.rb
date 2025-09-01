# frozen_string_literal: true

module RedmineMonitoring
  module Notifications
    class Dispatcher
      include RedmineMonitoring::Constants

      def call(error_id)
        settings = Setting.plugin_redmine_monitoring || {}
        return unless truthy?(settings['notify_enabled'])

        monitoring_error = MonitoringError.find(error_id)
        return unless allowed_severity?(monitoring_error, settings)
        return unless allowed_format?(monitoring_error, settings)

        fingerprint = build_fingerprint(monitoring_error)
        grouping_sec = settings.fetch('notify_grouping_window_sec', 300).to_i

        manager = AlertWindowManager.new(fingerprint, monitoring_error, grouping_sec)
        alert_window = manager.upsert!

        return if throttled?(fingerprint, settings)

        Deliverer.new(alert_window, monitoring_error, settings).deliver!
        manager.mark_notified!(alert_window)
      rescue StandardError => e
        Rails.logger.error "[Monitoring][notify] #{e.class}: #{e.message}"
      end

      private

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
          Rails.logger.info "[Monitoring][notify] throttled per-minute for fingerprint=#{fingerprint}"
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
        Rails.logger.warn "[Monitoring][notify] throttle-cache failed: #{e.class} #{e.message}"
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
