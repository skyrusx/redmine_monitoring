# frozen_string_literal: true

module MonitoringErrors
  module StatusHelper
    def activity_status(group)
      last_seen = to_time_with_zone(group.last_seen_at)
      return '—' unless last_seen

      diff_hours = (Time.current - last_seen).to_i / 3600
      status_key = diff_hours > 23 ? :not_active : :active

      { status: status_key, info: I18n.t("label_#{status_key}") }
    end
  end
end
