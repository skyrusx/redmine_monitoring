# frozen_string_literal: true

module RedmineMonitoring
  module Notifications
    class PayloadBuilder
      def initialize(error)
        @error = error
      end

      def call
        {
          headline: "[#{@error.severity.to_s.upcase}] " \
                    "#{@error.error_class} at " \
                    "#{@error.controller_name}##{@error.action_name}",
          severity: @error.severity, status: @error.status_code, format: @error.format,
          snippet: @error.message.to_s.truncate(300),
          backtrace: @error.backtrace.split("\n"),
          backtrace_limit: Setting.plugin_redmine_monitoring['notify_include_backtrace_lines'].to_i,
          url: Rails.application.routes.url_helpers.monitoring_errors_path
        }
      end
    end
  end
end
