module RedmineMonitoring
  class Middleware
    include RedmineMonitoring::Constants

    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, response = @app.call(env)

      severity = MonitoringError.severity_for(status)
      log_http_error(status, env)
      save_error_to_db(status: status, env: env, severity: severity)

      [status, headers, response]
    rescue => e
      severity = MonitoringError.severity_for(status, true)
      log_exception(e, env)
      save_error_to_db(exception: e, env: env, severity: severity)

      raise
    end

    private

    def log_exception(exception, env)
      logger = monitoring_logger
      logger.error "[Monitoring] #{exception.class}: #{exception.message}"
      logger.error exception.backtrace.join("\n")
      logger.error "URL: #{env['REQUEST_METHOD']} #{env['PATH_INFO']}"
    end

    def log_http_error(status, env)
      logger = monitoring_logger
      logger.warn "[Monitoring] HTTP #{status} on #{env['REQUEST_METHOD']} #{env['PATH_INFO']}"
    end

    def save_error_to_db(exception: nil, status: nil, env: , severity: "fatal")
      request = ActionDispatch::Request.new(env)
      controller_instance = env['action_controller.instance']

      return unless MonitoringError.allow_severity?(severity)
      return unless MonitoringError.allow_format?(safe_format(request))

      error_params = {
        exception_class: exception_class(exception, status),
        error_class: exception ? exception.class.to_s : "HTTP #{status}",
        message: exception ? exception.message.to_s : ([status, HTTP_STATUS_TEXT[status]].join(" ") rescue "Error #{status}"),
        backtrace: exception ? Array(exception.backtrace).join("\n") : "",
        status_code: exception ? 500 : status,
        controller_name: controller_instance&.class&.name || request.params['controller'],
        action_name: controller_instance&.action_name || request.params['action'],
        format: safe_format(request),
        file: exception ? backtrace_file_line(exception).first : "",
        line: exception ? backtrace_file_line(exception).last : "",
        user_id: (User.current&.id rescue nil),
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        referer: request.referer,
        params: safe_params(request.params).to_json,
        headers: filtered_headers(request).to_json,
        env: Rails.env,
        severity: severity
      }

      MonitoringError.create!(error_params)
    rescue => e
      logger = monitoring_logger
      logger.error "[Monitoring] Ошибка при сохранении HTTP #{status}: #{e.class} #{e.message}"
    end

    def safe_params(params)
      return {} unless params
      hash = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h
      hash.except(:controller, :action)
    rescue
      {}
    end

    def filtered_headers(request)
      raw = request.headers.env.slice(*USEFUL_HEADERS)
      raw.transform_values { |value| value.is_a?(String) ? value : value.to_s }
    end

    def safe_format(request)
      (request.format&.symbol || :html).to_s
    rescue
      'html'
    end

    def backtrace_file_line(exception)
      first = Array(exception.backtrace).first
      if first && first =~ /(.*):(\d+):in/
        [$1, $2.to_i]
      else
        [nil, nil]
      end
    end

    def monitoring_logger
      Logger.new("log/monitoring.log")
    end

    def exception_class(exception, status)
      return exception.class.to_s if exception

      case status.to_i
      when 100..199 then "Informational"
      when 200..299 then "Success"
      when 300..399 then "Redirect"
      when 400..499 then "ClientError"
      when 500..599 then "ServerError"
      else "UnknownHTTPStatus"
      end
    end
  end
end
