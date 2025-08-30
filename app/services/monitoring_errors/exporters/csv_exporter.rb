# frozen_string_literal: true

module MonitoringErrors
  module Exporters
    class CsvExporter
      def initialize(errors, batch_size, attributes, locale)
        @errors = errors
        @batch_size = batch_size
        @attributes = attributes
        @locale = locale
      end

      def call
        Redmine::Export::CSV.generate(headers: true, encoding: 'UTF-8', col_sep: ';') do |csv|
          csv << @attributes.map { |attr| I18n.t("label_#{attr}", locale: @locale) }

          @errors.find_in_batches(batch_size: @batch_size) do |batch|
            batch.each do |error|
              csv << @attributes.map { |attr| error.public_send(attr) }
            end
          end
        end
      end
    end
  end
end
