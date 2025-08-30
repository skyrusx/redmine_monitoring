# frozen_string_literal: true

module MonitoringErrors
  class Tester
    include RedmineMonitoring::Constants

    def self.call(request, severity)
      MonitoringError.create!(build_error_attributes(request, severity))
    end

    def self.safe_format(request)
      (request.format&.symbol || :html).to_s
    rescue StandardError
      'html'
    end

    def self.safe_params(params)
      return {} unless params

      params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h
    rescue StandardError
      {}
    end

    def self.filtered_headers(request)
      raw = request.headers.env.slice(*USEFUL_HEADERS)
      raw.transform_values { |value| value.is_a?(String) ? value : value.to_s }
    end

    private_class_method def self.build_error_attributes(request, severity)
      {
        exception_class: I18n.t('label_fake_exception_class'),
        error_class: I18n.t('label_fake_error_class'),
        message: I18n.t('label_fake_message'),
        backtrace: caller.join("\n"),
        status_code: DEFAULT_STATUS_CODE,
        controller_name: I18n.t('label_fake_controller_name'),
        action_name: I18n.t('label_fake_action_name'),
        format: safe_format(request),
        file: __FILE__,
        line: __LINE__,
        user_id: User.current&.id,
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        referer: request.referer,
        params: safe_params(request.params).to_json,
        headers: filtered_headers(request).to_json,
        env: Rails.env,
        severity: severity
      }
    end
  end
end
