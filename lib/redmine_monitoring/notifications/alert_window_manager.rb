# frozen_string_literal: true

module RedmineMonitoring
  module Notifications
    class AlertWindowManager
      def initialize(fingerprint, monitoring_error, grouping_sec)
        @fingerprint = fingerprint
        @monitoring_error = monitoring_error
        @grouping_sec = grouping_sec
      end

      # Найти/создать окно и инкрементировать счётчик ошибок
      def upsert!
        now = Time.current
        alert = MonitoringAlert.where(fingerprint: @fingerprint).order(id: :desc).first

        return create_new!(now) if alert.nil? || alert.window_started_at < (now - @grouping_sec)

        update_existing!(alert, now)
      end

      def mark_notified!(alert)
        return unless alert

        alert.update_columns(last_notified_count: alert.last_notified_count.to_i + 1)
      end

      private

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
