# frozen_string_literal: true

module RedmineMonitoring
  class RequestSubscriber
    EVENT = 'process_action.action_controller'
    ASSET_PREFIXES = %w[/assets /packs /favicon.ico /robots.txt].freeze

    def self.attach!
      if @attached
        RedmineMonitoring::OperationalLogger.once(:request_subscriber_already_attached,
                                                  message: 'request subscriber already attached')
        return
      end

      ActiveSupport::Notifications.subscribe(EVENT) { |*args| instance.call(*args) }
      @attached = true
      RedmineMonitoring::OperationalLogger.info('request subscriber attached')
    end

    def self.instance
      @instance ||= new
    end

    def call(_event_name, start_time, finish_time, _event_id, payload)
      return unless metrics_enabled?

      request_format = normalized_format(payload[:format])
      return unless allowed_format?(request_format)

      request_path, http_method = extract_path_and_method(payload)
      return if skip_path?(request_path)

      status_code, duration_ms = compute_status_and_duration(payload, start_time, finish_time)
      return if ignore_fast_success?(status_code, duration_ms)

      persist_request(
        payload,
        finished_at: finish_time,
        request: {
          path: request_path,
          method: http_method,
          format: request_format,
          status_code: status_code,
          duration_ms: duration_ms
        }
      )
    rescue StandardError => e
      RedmineMonitoring::OperationalLogger.warn("RequestSubscriber failed: #{e.class}: #{e.message}")
    end

    private

    # --- orchestration helpers

    def allowed_format?(request_format)
      MonitoringError.allow_format?(request_format)
    end

    def persist_request(payload, finished_at:, request:)
      header_info = RedmineMonitoring::HeaderExtractor.new(payload).extract

      MonitoringRequest.create!(
        RedmineMonitoring::RequestAttributesBuilder.new(
          payload: payload,
          finished_at: finished_at,
          request: request,
          header_info: header_info
        ).build
      )
    end

    # --- feature flags / settings

    def metrics_enabled?
      settings = plugin_settings
      enabled = settings['enable_metrics'] || settings[:enable_metrics]
      unless enabled
        RedmineMonitoring::OperationalLogger.once(:metrics_disabled,
                                                  message: 'metrics collection disabled by settings')
      end
      enabled
    rescue StandardError
      RedmineMonitoring::OperationalLogger.once(:metrics_settings_unavailable,
                                                level: :warn,
                                                message: 'metrics settings unavailable')
      false
    end

    def plugin_settings
      return {} unless Setting.respond_to?(:plugin_redmine_monitoring)

      Setting.plugin_redmine_monitoring || {}
    rescue StandardError
      {}
    end

    def slow_request_threshold
      Integer(plugin_settings['slow_request_threshold_ms'], exception: false) || 0
    rescue StandardError
      0
    end

    # --- request parsing

    def normalized_format(raw_format)
      MonitoringError.normalize_format(raw_format.presence || 'html')
    end

    def extract_path_and_method(payload)
      [safe_string(payload[:path]), safe_string(payload[:method]).upcase]
    end

    def compute_status_and_duration(payload, start_time, finish_time)
      duration_ms = ((finish_time - start_time) * 1000.0).round
      status_code = yield_status_code(payload)
      [status_code, duration_ms]
    end

    def yield_status_code(payload)
      (payload[:status] || (payload[:exception] ? 500 : nil)).to_i
    end

    def ignore_fast_success?(status_code, duration_ms)
      threshold = slow_request_threshold
      status_code < 400 && threshold.positive? && duration_ms < threshold
    end

    def skip_path?(request_path)
      return true if request_path.blank?

      ASSET_PREFIXES.any? { |prefix| request_path.start_with?(prefix) }
    end

    # --- generic safety helpers

    def safe_string(value)
      value.to_s
    rescue StandardError
      ''
    end
  end
end
