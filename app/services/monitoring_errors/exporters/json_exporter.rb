# frozen_string_literal: true

module MonitoringErrors
  module Exporters
    class JsonExporter
      def initialize(errors, batch_size, attributes)
        @errors = errors
        @batch_size = batch_size
        @attributes = attributes
      end

      def call
        @errors.find_in_batches(batch_size: @batch_size).flat_map do |batch|
          batch.map { |error| error.as_json(only: @attributes) }
        end.to_json
      end
    end
  end
end
