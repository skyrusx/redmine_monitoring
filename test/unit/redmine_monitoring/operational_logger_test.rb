# frozen_string_literal: true

require File.expand_path('../../test_helper', __dir__)
require File.expand_path('../../../lib/redmine_monitoring/operational_logger', __dir__)

module RedmineMonitoring
  class OperationalLoggerTest < ActiveSupport::TestCase
    setup do
      OperationalLogger.reset_once!
    end

    test 'once logs a message only once per key' do
      logger = MemoryLogger.new

      OperationalLogger.stub(:logger, logger) do
        OperationalLogger.once(:same_key, message: 'first')
        OperationalLogger.once(:same_key, message: 'second')
      end

      assert_equal ['[Monitoring][ops] first'], logger.infos
    end

    test 'supports warn and error levels' do
      logger = MemoryLogger.new

      OperationalLogger.stub(:logger, logger) do
        OperationalLogger.once(:warn_key, level: :warn, message: 'warned')
        OperationalLogger.error('failed')
      end

      assert_equal ['[Monitoring][ops] warned'], logger.warns
      assert_equal ['[Monitoring][ops] failed'], logger.errors
    end

    test 'supports debug blocks' do
      logger = MemoryLogger.new

      OperationalLogger.stub(:logger, logger) do
        OperationalLogger.debug { 'details' }
      end

      assert_equal ['details'], logger.debugs
    end

    test 'uses plugin log filename' do
      assert_equal 'redmine_monitoring.log', OperationalLogger::LOG_FILENAME
      assert_includes OperationalLogger.log_path, 'redmine_monitoring.log'
    end

    class MemoryLogger
      attr_reader :debugs, :infos, :warns, :errors

      def initialize
        @debugs = []
        @infos = []
        @warns = []
        @errors = []
      end

      def debug(message)
        debugs << message
      end

      def info(message)
        infos << message
      end

      def warn(message)
        warns << message
      end

      def error(message)
        errors << message
      end
    end
  end
end
