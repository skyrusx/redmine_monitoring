# frozen_string_literal: true

module RedmineMonitoring
  module Security
    class BrakemanApiRunner
      def initialize(app_path:, output_html:, options: {})
        @app_path = app_path
        @output_html = output_html
        @options = options
      end

      # Возвращает [payload_json_hash, html_or_nil]
      def run
        require 'brakeman'

        tracker = ::Brakeman.run(base_options.merge(symbolize_keys_shallow(@options)))
        report = ::Brakeman::Report.new(tracker)

        payload = parse_json_string!(report.to_json)
        html = @output_html ? report.to_html : nil

        [payload, html]
      rescue JSON::ParserError => e
        raise "Brakeman API produced invalid JSON: #{e.message}"
      end

      private

      def base_options
        {
          app_path: @app_path,
          quiet: true,
          print_report: false,
          output_formats: [],
          output_files: []
        }
      end

      def symbolize_keys_shallow(hash)
        return {} unless hash.is_a?(Hash)

        hash.transform_keys(&:to_sym)
      end

      def parse_json_string!(value)
        string = value.to_s
        raise JSON::ParserError, 'empty JSON' if string.strip.empty?

        JSON.parse(string)
      end
    end
  end
end
