# frozen_string_literal: true

module MonitoringErrors
  module TimeHelper
    def to_time_with_zone(value)
      return unless value
      return value.in_time_zone if value.respond_to?(:in_time_zone)

      Time.zone.parse(value.to_s)
    rescue StandardError
      nil
    end
  end
end
