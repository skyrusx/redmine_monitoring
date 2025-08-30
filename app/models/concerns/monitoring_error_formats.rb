# frozen_string_literal: true

module MonitoringErrorFormats
  extend ActiveSupport::Concern

  class_methods do
    def normalize_format(value)
      value.to_s.strip.downcase.presence || 'html'
    end

    def allow_format?(value)
      enabled_formats.include?(value.to_s.strip.upcase)
    end
  end
end
