module RedmineMonitoring
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      begin
        status, headers, response = @app.call(env)
        log_http_error(status, env) if status >= 400
        [status, headers, response]
      rescue => e
        log_exception(e, env)
        save_error_to_db(e, env)
      end
    end

    private

    def log_exception(exception, env)
      Rails.logger.error "[Monitoring] #{exception.class}: #{exception.message}"
      Rails.logger.error exception.backtrace.join("\n")
      Rails.logger.error "URL: #{env['REQUEST_METHOD']} #{env['PATH_INFO']}"
    end

    def log_http_error(status, env)
      Logger.new("log/monitoring.log")
      Rails.logger.warn "[Monitoring] HTTP #{status} on #{env['REQUEST_METHOD']} #{env['PATH_INFO']}"
    end

    def save_error_to_db(exception, env)
      request = ActionDispatch::Request.new(env)
      controller_instance = env['action_controller.instance']

      MonitoringError.create(
        exception_class: exception.class.to_s,
        error_class: exception.class.to_s,
        message: exception.message.to_s,
        backtrace: Array(exception.backtrace).join("\n"),
        status_code: 500,
        controller_name: controller_instance&.class&.name || request.params['controller'],
        action_name: controller_instance&.action_name || request.params['action'],
        format: safe_format(request),
        file: backtrace_file_line(exception).first,
        line: backtrace_file_line(exception).last,
        user_id: (User.current&.id rescue nil),
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        referer: request.referer,
        params: safe_params(request.params).to_json,
        headers: filtered_headers(request).to_json,
        env: Rails.env,
        severity: 'fatal'
      )
    end

    def safe_params(params)
      return {} unless params
      hash = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h
      hash.except(:controller, :action)
    rescue
      {}
    end

    def filtered_headers(request)
      raw = request.headers.env.slice(*MonitoringError::USEFUL_HEADERS)
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
  end
end
