# frozen_string_literal: true

module RedmineMonitoring
  class ErrorAttributesBuilder
    include Constants

    def initialize(request:, controller_instance:, exception:, status:, severity:)
      @request = request
      @controller_instance = controller_instance
      @exception = exception
      @status = status
      @severity = severity
    end

    def build
      (exception ? exception_attributes : http_error_attributes)
        .merge(request_context_attributes)
        .merge(env: Rails.env, severity: severity)
    end

    private

    attr_reader :request, :controller_instance, :exception, :status, :severity

    # --- exception/http parts

    def exception_attributes
      file, line = backtrace_file_line(exception)
      {
        exception_class: exception.class.to_s,
        error_class: exception.class.to_s,
        message: exception.message.to_s,
        backtrace: Array(exception.backtrace).join("\n"),
        status_code: 500,
        file: file,
        line: line
      }
    end

    def http_error_attributes
      {
        exception_class: http_exception_class(status),
        error_class: "HTTP #{status}",
        message: http_error_message(status),
        backtrace: '',
        status_code: status,
        file: '',
        line: ''
      }
    end

    # --- request context

    def request_context_attributes
      {
        controller_name: controller_instance&.class&.name || request.params['controller'],
        action_name: controller_instance&.action_name || request.params['action'],
        format: safe_format(request),
        user_id: safe_current_user_id,
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        referer: request.referer,
        params: safe_params(request.params).to_json,
        headers: filtered_headers(request).to_json
      }
    end

    # --- safety helpers

    def safe_params(params)
      return {} unless params

      params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h
    rescue StandardError
      {}
    end

    def filtered_headers(req)
      raw = req.headers.env.slice(*USEFUL_HEADERS)
      raw.transform_values { |v| v.is_a?(String) ? v : v.to_s }
    end

    def safe_format(req)
      (req.format&.symbol || :html).to_s
    rescue StandardError
      'html'
    end

    def safe_current_user_id
      User.current&.id
    rescue StandardError
      nil
    end

    # --- backtrace / classification

    def backtrace_file_line(exception)
      first = Array(exception.backtrace).first
      return [nil, nil] if first.blank?

      match = first.match(/(.*):(\d+):in/)
      match ? [match[1], match[2].to_i] : [nil, nil]
    end

    def http_exception_class(status_code)
      case status_code.to_i
      when 100..199 then 'Informational'
      when 200..299 then 'Success'
      when 300..399 then 'Redirect'
      when 400..499 then 'ClientError'
      when 500..599 then 'ServerError'
      else 'UnknownHTTPStatus'
      end
    end

    def http_error_message(status_code)
      [status_code, HTTP_STATUS_TEXT[status_code]].join(' ')
    rescue StandardError
      "Error #{status_code}"
    end
  end
end
