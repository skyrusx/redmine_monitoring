# frozen_string_literal: true

module MonitoringErrors
  module Exporters
    class CsvExporter
      def initialize(records, batch_size, attributes, locale)
        @records = records
        @batch_size = batch_size
        @attributes = attributes
        @locale = locale
      end

      def call
        Redmine::Export::CSV.generate(headers: true, encoding: 'UTF-8', col_sep: ';') do |csv|
          csv << @attributes.map { |attr| I18n.t("label_#{attr}", locale: @locale) }

          @records.find_in_batches(batch_size: @batch_size) do |batch|
            batch.each do |record|
              csv << @attributes.map { |attr| record.public_send(attr) }
            end
          end
        end
      end
    end
  end
end
