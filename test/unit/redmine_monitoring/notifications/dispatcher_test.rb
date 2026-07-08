# frozen_string_literal: true

require File.expand_path('../../../test_helper', __dir__)

module RedmineMonitoring
  module Notifications
    class DispatcherTest < ActiveSupport::TestCase
      setup do
        require_redmine_application!('MonitoringAlert', 'MonitoringAlertChannel', 'MonitoringError', 'Setting')

        MonitoringAlertChannel.delete_all
        MonitoringAlert.delete_all
        MonitoringError.delete_all

        Setting.plugin_redmine_monitoring = {
          'notify_enabled' => '1',
          'notify_channels' => ['email'],
          'notify_severity_min' => 'error',
          'notify_formats' => ['html'],
          'notify_grouping_window_sec' => '300',
          'notify_throttle_per_group_per_min' => '5'
        }
      end

      test 'dispatcher creates alert window and delivers allowed error' do
        error = create_error
        delivered = false
        deliverer = Object.new
        deliverer.define_singleton_method(:deliver!) { delivered = true }

        Deliverer.stub(:new, deliverer) do
          Dispatcher.new.call(error.id)
        end

        assert delivered
        assert_equal 1, MonitoringAlert.count
        assert_equal 1, MonitoringAlert.first.last_notified_count
      end

      private

      def create_error
        MonitoringError.create!(
          error_class: 'RuntimeError',
          message: 'boom',
          severity: 'error',
          format: 'html',
          status_code: 500,
          skip_notifications: true
        )
      end
    end
  end
end
