# frozen_string_literal: true

module MonitoringErrors
  module JsonHelper
    def pretty_json(raw, fallback: '-')
      return fallback if raw.blank?

      parsed = raw.is_a?(String) ? JSON.parse(raw) : raw
      JSON.pretty_generate(parsed)
    rescue JSON::ParserError, TypeError
      raw.presence || fallback
    end
  end
end
