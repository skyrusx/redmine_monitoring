# frozen_string_literal: true

module RedmineMonitoring
  module Env
    module_function

    def dev_mode?
      return false unless dev_like?

      settings = Setting.plugin_redmine_monitoring || {}
      value = settings['dev_mode'] || settings[:dev_mode]
      ActiveModel::Type::Boolean.new.cast(value)
    rescue StandardError
      false
    end

    def dev_like?
      %w[development test].include?(env_name)
    end

    def prod?
      Rails.env.production?
    end

    def test?
      Rails.env.test?
    end

    def development?
      Rails.env.development?
    end

    def env_name
      Rails.env.to_s
    end
  end
end
