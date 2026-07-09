# frozen_string_literal: true

require 'json'

module RedmineMonitoring
  class DataSanitizer
    MASK = '[FILTERED]'

    class << self
      def settings
        return {} unless defined?(Setting) && Setting.respond_to?(:plugin_redmine_monitoring)

        Setting.plugin_redmine_monitoring || {}
      rescue StandardError
        {}
      end

      def sanitize_params(value)
        truncate_json(mask(value), limit_for('params_max_bytes'))
      end

      def sanitize_headers(value)
        return nil unless enabled?('capture_headers', true)

        truncate_json(mask(value), limit_for('headers_max_bytes'))
      end

      def sanitize_env(value)
        return nil unless enabled?('capture_env', true)

        truncate_string(value, limit_for('env_max_bytes'))
      end

      def sanitize_backtrace(value)
        truncate_string(value, limit_for('backtrace_max_bytes'))
      end

      def mask(value)
        return value unless enabled?('mask_sensitive_data', true)

        case value
        when Hash
          value.each_with_object({}) do |(key, item), result|
            result[key] = sensitive_key?(key) ? MASK : mask(item)
          end
        when Array
          value.map { |item| mask(item) }
        else
          value
        end
      end

      def truncate_json(value, limit)
        truncate_string(JSON.generate(value), limit)
      rescue StandardError
        '{}'
      end

      def truncate_string(value, limit)
        string = value.to_s
        return string if limit <= 0 || string.bytesize <= limit

        string.byteslice(0, limit).to_s
      end

      private

      def sensitive_key?(key)
        normalized = key.to_s.downcase
        sensitive_keys.any? { |sensitive| normalized.include?(sensitive) }
      end

      def sensitive_keys
        configured = Array(setting_value('sensitive_keys'))
                     .flat_map { |value| value.to_s.split(/[\s,]+/) }
                     .reject(&:empty?)
        configured.empty? ? RedmineMonitoring::Constants::DEFAULT_SETTINGS[:sensitive_keys] : configured
      end

      def limit_for(key)
        value = setting_value(key)
        value = RedmineMonitoring::Constants::DEFAULT_SETTINGS[key.to_sym] if value.nil?
        value.to_i
      rescue StandardError
        0
      end

      def enabled?(key, fallback)
        value = setting_value(key)
        value = fallback if value.nil?

        if defined?(ActiveModel::Type::Boolean)
          ActiveModel::Type::Boolean.new.cast(value)
        else
          !%w[0 false off no].include?(value.to_s.downcase)
        end
      end

      def setting_value(key)
        settings[key] || settings[key.to_sym]
      end
    end
  end
end
