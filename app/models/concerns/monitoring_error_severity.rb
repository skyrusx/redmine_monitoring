# frozen_string_literal: true

module MonitoringErrorSeverity
  extend ActiveSupport::Concern
  include RedmineMonitoring::Constants

  class_methods do
    def allow_severity?(severity)
      log_levels.include?(severity.to_s)
    end

    def severity_for(status_code, exception = nil)
      return SEVERITIES[0] if exception

      code = status_code.to_i
      case code
      when 500..599 then SEVERITIES[1]
      when 400..499 then SEVERITIES[2]
      else SEVERITIES[3]
      end
    end
  end
end
