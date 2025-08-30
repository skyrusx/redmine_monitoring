require 'prawn'
require 'axlsx'

module MonitoringErrors
  class Export
    include RedmineMonitoring::Constants

    def initialize(errors, batch_size: DEFAULT_BATCH_SIZE, locale: :ru)
      @errors = errors
      @batch_size = batch_size
      @attributes = MonitoringError.attribute_names
      @locale = locale
    end

    def export_csv
      Exporters::CsvExporter.new(@errors, @batch_size, @attributes, @locale).call
    end

    def export_json
      Exporters::JsonExporter.new(@errors, @batch_size, @attributes).call
    end

    def export_pdf
      Exporters::PdfExporter.new(@errors, @batch_size, @attributes).call
    end

    def export_xlsx
      Exporters::XlsxExporter.new(@errors, @batch_size, @attributes, @locale).call
    end
  end
end
