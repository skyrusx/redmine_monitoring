require 'prawn'
require 'axlsx'

module MonitoringErrors
  class Export
    include RedmineMonitoring::Constants

    def initialize(records, batch_size: DEFAULT_BATCH_SIZE, locale: :ru)
      @records = records
      @batch_size = batch_size
      @attributes = records.klass.attribute_names
      @locale = locale
    end

    def export_csv
      Exporters::CsvExporter.new(@records, @batch_size, @attributes, @locale).call
    end

    def export_json
      Exporters::JsonExporter.new(@records, @batch_size, @attributes).call
    end

    def export_pdf
      Exporters::PdfExporter.new(@records, @batch_size, @attributes).call
    end

    def export_xlsx
      Exporters::XlsxExporter.new(@records, @batch_size, @attributes, @locale).call
    end
  end
end
