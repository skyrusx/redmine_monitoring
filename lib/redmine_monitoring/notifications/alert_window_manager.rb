# frozen_string_literal: true

module RedmineMonitoring
  module Notifications
    class AlertWindowManager
      def initialize(fingerprint, monitoring_error, grouping_sec)
        @fingerprint = fingerprint.to_s
        @monitoring_error = monitoring_error
        @grouping_sec = grouping_sec.to_i
      end

      # Найти/создать окно и инкрементировать счётчик ошибок
      def upsert!
        now = Time.current
        alert = MonitoringAlert.where(fingerprint: @fingerprint).order(id: :desc).first

        return create_new!(now) if alert.nil? || alert.window_started_at.blank?
        return create_new!(now) if window_expired?(alert, now)

        update_existing!(alert, now) # внутри окна
      end

      def mark_notified!(*args, alert: nil)
        alert ||= args.first
        return unless alert

        attrs = notification_updates_for(alert)
        return alert if attrs.empty?

        alert.with_lock { alert.update!(attrs) } # валидно, без скипа колбэков
        alert
      end

      private

      def notification_updates_for(alert)
        attrs = {}
        attrs[:last_notified_at] = Time.current if alert.has_attribute?(:last_notified_at)
        attrs[:last_notified_count] = alert.last_notified_count.to_i + 1 if alert.has_attribute?(:last_notified_count)
        attrs
      end

      def window_expired?(alert, now)
        @grouping_sec.positive? && alert.window_started_at < (now - @grouping_sec)
      end

      def create_new!(now)
        MonitoringAlert.create!(
          fingerprint: @fingerprint,
          first_error_id: @monitoring_error.id,
          last_error_id: @monitoring_error.id,
          errors_count: 1,
          first_seen_at: now,
          last_seen_at: now,
          last_notified_count: 0,
          window_started_at: now
        )
      end

      def update_existing!(alert, now)
        bump_in_window!(alert, now)
      end

      def restart_window!(alert, now)
        alert.update_columns(
          first_error_id: @monitoring_error.id,
          last_error_id: @monitoring_error.id,
          errors_count: 1,
          last_seen_at: now,
          window_started_at: now
        )
        alert
      end

      def bump_in_window!(alert, now)
        alert.update_columns(
          last_error_id: @monitoring_error.id,
          errors_count: alert.errors_count.to_i + 1,
          last_seen_at: now
        )
        alert
      end
    end
  end
end
