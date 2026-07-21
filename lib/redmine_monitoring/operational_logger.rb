# frozen_string_literal: true

require 'fileutils'
require 'logger'

module RedmineMonitoring
  module OperationalLogger
    module_function

    PREFIX = '[Monitoring][ops]'
    LOG_FILENAME = 'redmine_monitoring.log'

    def info(message)
      logger.info("#{PREFIX} #{message}")
    rescue StandardError
      nil
    end

    def debug(message = nil, &block)
      logger.debug(message || block&.call)
    rescue StandardError
      nil
    end

    def warn(message)
      logger.warn("#{PREFIX} #{message}")
    rescue StandardError
      nil
    end

    def error(message)
      logger.error("#{PREFIX} #{message}")
    rescue StandardError
      nil
    end

    def once(key, level: :info, message:)
      return if logged_once?(key)

      mark_logged(key)
      public_send(level, message)
    rescue StandardError
      nil
    end

    def reset_once!
      @logged_once = {}
      @logger = nil
    end

    def logger
      @logger ||= build_logger
    rescue StandardError
      Logger.new($stdout)
    end

    def log_path
      if defined?(Rails) && Rails.respond_to?(:root) && Rails.root
        Rails.root.join('log', LOG_FILENAME).to_s
      else
        File.expand_path(File.join('log', LOG_FILENAME))
      end
    end

    def logged_once?(key)
      logged_once.key?(key.to_s)
    end

    def mark_logged(key)
      logged_once[key.to_s] = true
    end

    def logged_once
      @logged_once ||= {}
    end

    def build_logger
      path = log_path
      FileUtils.mkdir_p(File.dirname(path))
      logger = Logger.new(path)
      logger.level = rails_logger_level
      logger
    end

    def rails_logger_level
      return Logger::INFO unless defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
      return Logger::INFO unless Rails.logger.respond_to?(:level)

      Rails.logger.level || Logger::INFO
    rescue StandardError
      Logger::INFO
    end
  end
end
