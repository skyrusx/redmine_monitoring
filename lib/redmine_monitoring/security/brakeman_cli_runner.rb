# frozen_string_literal: true

require 'open3'

module RedmineMonitoring
  module Security
    class BrakemanCliRunner
      SUCCESS_EXITCODES = [0, 3].freeze

      def initialize(app_path:, extra_args: [])
        @app_path = app_path
        @extra_args = Array(extra_args)
      end

      # Возвращает [json_stdout, html_stdout_or_nil]
      def run_once(output_html:)
        json = capture('json', 2000)
        html = output_html ? capture('html', 1000) : nil
        [json, html]
      end

      private

      attr_reader :app_path, :extra_args

      def capture(format, head_limit)
        cmd = base_cmd + ['-f', format, '-o', '-']
        stdout, stderr, status = Open3.capture3(*cmd, chdir: app_path)

        unless SUCCESS_EXITCODES.include?(status.exitstatus)
          message = +"Brakeman #{format.upcase} failed (exit #{status.exitstatus}).\n"
          message << "CMD: #{cmd.join(' ')}\n"
          message << "STDERR:\n#{stderr.to_s.strip}\n"
          head = stdout.to_s[0, head_limit]
          message << "STDOUT(head):\n#{head}\n" if head.present?
          raise message
        end

        stdout
      rescue Errno::ENOENT => e
        raise "Brakeman CLI not found: #{e.message}"
      end

      def base_cmd
        %w[bundle exec brakeman -q] + extra_args + ['-p', app_path]
      end
    end
  end
end
