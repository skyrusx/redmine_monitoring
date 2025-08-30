# frozen_string_literal: true

module RedmineMonitoring
  class Middleware
    include Constants

    def initialize(app)
      @app = app
    end

    def call(env)
      status = nil
      status, headers, response = @app.call(env)

      severity = MonitoringError.severity_for(status)
      log_http_error(status, env)
      reporter.save(env: env, status: status, severity: severity)

      [status, headers, response]
    rescue StandardError => e
      severity = MonitoringError.severity_for(status, true)
      log_exception(e, env)
      reporter.save(env: env, exception: e, severity: severity)
      raise
    end

    private

    # --- Logging

    def log_exception(exception, env)
      monitoring_logger.error "[Monitoring] #{exception.class}: #{exception.message}"
      monitoring_logger.error Array(exception.backtrace).join("\n")
      monitoring_logger.error "URL: #{env['REQUEST_METHOD']} #{env['PATH_INFO']}"
    end

    def log_http_error(status, env)
      monitoring_logger.warn "[Monitoring] HTTP #{status} on #{env['REQUEST_METHOD']} #{env['PATH_INFO']}"
    end

    def monitoring_logger
      @monitoring_logger ||= Logger.new('log/monitoring.log')
    end

    def reporter
      @reporter ||= RedmineMonitoring::ErrorReporter.new(logger: monitoring_logger)
    end
  end
end
