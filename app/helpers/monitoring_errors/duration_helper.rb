# frozen_string_literal: true

module MonitoringErrors
  module DurationHelper
    include RedmineMonitoring::Constants

    DURATION_LABELS = {
      years: I18n.t('label_short_year'),
      months: I18n.t('label_short_month'),
      days: I18n.t('label_short_day'),
      hours: I18n.t('label_short_hour'),
      minutes: I18n.t('label_short_minute'),
      seconds: I18n.t('label_short_second')
    }.freeze

    def human_duration(group)
      from_time = to_time_with_zone(group.first_seen_at)
      to_time = to_time_with_zone(group.last_seen_at)

      return I18n.t('label_no') unless from_time && to_time

      seconds = (to_time - from_time).to_i
      return I18n.t('label_no') if seconds <= 0

      "[#{format_duration_parts(seconds)}]"
    end

    private

    def format_duration_parts(total_seconds)
      DURATION_UNITS.map do |key, unit_seconds|
        value, total_seconds = total_seconds.divmod(unit_seconds)
        "#{value} #{DURATION_LABELS[key]}" unless value.zero?
      end.compact.join(' ')
    end
  end
end
