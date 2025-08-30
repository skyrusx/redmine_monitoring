# frozen_string_literal: true

module RedmineMonitoring
  class RequestAttributesBuilder
    def initialize(payload:, finished_at:, request:, header_info:)
      @payload = payload
      @finished_at = finished_at
      @request = request
      @header_info = header_info
    end

    def build
      base_attributes
        .merge(controller_attributes)
        .merge(performance_attributes)
        .merge(header_attributes)
        .merge(meta_attributes)
    end

    private

    attr_reader :payload, :finished_at, :request, :header_info

    def base_attributes
      request_path = request[:path].to_s
      request_method = request[:method]

      {
        created_at: finished_at,
        method: request_method.to_s.upcase,
        path: request_path,
        normalized_path: MonitoringRequest.normalize_path(request_path, method: request_method),
        format: request[:format].to_s.downcase,
        status_code: request[:status_code].to_i,
        duration_ms: request[:duration_ms].to_i
      }
    end

    def controller_attributes
      {
        controller_name: safe_string(payload[:controller]),
        action_name: safe_string(payload[:action])
      }
    end

    def performance_attributes
      {
        view_ms: payload[:view_runtime].to_i,
        db_ms: payload[:db_runtime].to_i
      }
    end

    def header_attributes
      {
        bytes_sent: header_info[:bytes_sent].to_i,
        ip_address: header_info[:ip].to_s,
        user_agent: header_info[:user_agent].to_s,
        referer: header_info[:referer].to_s
      }
    end

    def meta_attributes
      { user_id: safe_current_user_id, env: Rails.env }
    end

    # --- local safety helpers (избегаем зависимости от внешних утилит)

    def safe_string(value)
      value.to_s
    rescue StandardError
      ''
    end

    def safe_current_user_id
      User.current&.id
    rescue StandardError
      nil
    end
  end
end
