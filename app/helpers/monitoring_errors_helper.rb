# frozen_string_literal: true

module MonitoringErrorsHelper
  include MonitoringErrors::ExportHelper
  include MonitoringErrors::TimeHelper
  include MonitoringErrors::DurationHelper
  include MonitoringErrors::StatusHelper
  include MonitoringErrors::JsonHelper
  include MonitoringErrors::HtmlHelper
  include MonitoringErrors::SecurityHelper
end
