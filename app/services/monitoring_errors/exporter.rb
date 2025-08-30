# frozen_string_literal: true

module MonitoringErrors
  class Exporter
    include RedmineMonitoring::Constants

    def initialize(scope)
      @scope = scope
    end

    def send(format, controller)
      data = MonitoringErrors::Export.new(@scope).public_send("export_#{format}")
      controller.send_data(
        data,
        filename: filename(format),
        type: MIME_TYPES[format]
      )
    end

    private

    def filename(format)
      "monitoring-errors__#{Time.zone.today}.#{format}"
    end
  end
end
