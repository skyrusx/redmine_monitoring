# frozen_string_literal: true

module RedmineMonitoring
  class Middleware
    include Constants

    def initialize(app)
      @app = app
    end

    def call(env)
      cur = RedmineMonitoring::BulletIntegration::Current
      req = ActionDispatch::Request.new(env)
      cur.path = safe_fullpath(req)
      cur.user_id = safe_current_user_id

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
    ensure
      # очищаем контекст после Bullet::Rack
      RedmineMonitoring::BulletIntegration::Current.reset_all
    end

    private

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

    def safe_fullpath(request)
      request.fullpath.to_s[0, 2048]
    rescue StandardError
      ''
    end

    def safe_current_user_id
      user = User.current

      return nil unless user
      return nil if user.respond_to?(:anonymous?) && user.anonymous?

      user.id
    rescue StandardError
      nil
    end
  end
end
