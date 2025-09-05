# frozen_string_literal: true

module RedmineMonitoring
  module Constants
    ENABLED_FORMATS = %w[HTML JSON CSV PDF XLSX XML].freeze

    MIME_TYPES = {
      csv: 'text/csv',
      json: 'application/json',
      pdf: 'application/pdf',
      xlsx: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    }.freeze

    EXPORT_FORMATS = {
      csv: :label_export_csv,
      xlsx: :label_export_xlsx,
      json: :label_export_json,
      pdf: :label_export_pdf
    }.freeze

    AVAILABLE_EXPORT_FORMATS = EXPORT_FORMATS.keys.freeze
  end
end
