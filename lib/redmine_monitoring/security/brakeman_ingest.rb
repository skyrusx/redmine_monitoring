# frozen_string_literal: true

require 'json'
require_relative 'brakeman_cli_runner'
require_relative 'brakeman_api_runner'

module RedmineMonitoring
  module Security
    class BrakemanIngest
      # компактная сигнатура под Metrics/ParameterLists
      def self.call!(**opts)
        params = default_params.merge(opts)
        mode = select_mode(params[:prefer])

        case mode
        when :api then run_api_or_fallback(params)
        when :cli then run_cli(params)
        else mode_auto(params)
        end
      end

      # ===== API режим =====
      def self.from_api!(app_path:, output_html:, options: {}, target_scan_id: nil)
        payload, html = BrakemanApiRunner.new(app_path: app_path, output_html: output_html, options: options).run

        target = target_scan_id && MonitoringSecurityScan.find_by(id: target_scan_id)
        scan = MonitoringSecurityScan.ingest_brakeman!(json: payload, html: html, target_scan: target)

        { scan: scan, mode: :api }
      end

      # ===== CLI режим =====
      def self.from_cli!(app_path:, output_html:, extra_args: [], target_scan_id: nil)
        runner = BrakemanCliRunner.new(app_path: app_path, extra_args: extra_args)
        json_str, html = runner.run_once(output_html: output_html)

        begin
          payload = parse_json_string!(json_str)
        rescue JSON::ParserError
          retry_args = (Array(extra_args) + %w[--no-exit-on-warn --no-exit-on-error]).uniq - ['-q']
          json_retry, html_retry = BrakemanCliRunner.new(app_path: app_path, extra_args: retry_args)
                                                    .run_once(output_html: output_html)

          payload = parse_json_string!(json_retry)
          html ||= html_retry
        end

        target = target_scan_id && MonitoringSecurityScan.find_by(id: target_scan_id)
        scan = MonitoringSecurityScan.ingest_brakeman!(json: payload, html: html, target_scan: target)

        { scan: scan, mode: :cli }
      end

      class << self
        private

        def default_params
          {
            app_path: Rails.root.to_s,
            prefer: :auto,
            output_html: true,
            options: {},
            extra_args: [],
            fallback_to_cli: true,
            target_scan_id: nil
          }
        end

        def run_api_or_fallback(params)
          from_api!(app_path: params[:app_path],
                    output_html: params[:output_html],
                    options: params[:options],
                    target_scan_id: params[:target_scan_id])
        rescue LoadError, NameError => e
          raise e unless params[:fallback_to_cli]

          run_cli(params)
        end

        def run_cli(params)
          from_cli!(app_path: params[:app_path],
                    output_html: params[:output_html],
                    extra_args: params[:extra_args],
                    target_scan_id: params[:target_scan_id])
        end

        def mode_auto(params)
          return run_api_or_fallback(params) if api_supported?

          run_cli(params)
        end

        def select_mode(prefer)
          case (prefer || :auto).to_sym
          when :api then :api
          when :cli then :cli
          else :auto
          end
        end

        def api_supported?
          return true if defined?(::Brakeman)

          require 'brakeman'
          true
        rescue LoadError
          false
        end

        def parse_json_string!(value)
          string = value.to_s
          raise JSON::ParserError, 'empty JSON' if string.strip.empty?

          JSON.parse(string)
        end
      end
    end
  end
end
