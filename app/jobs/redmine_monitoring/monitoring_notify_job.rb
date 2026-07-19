# frozen_string_literal: true

module RedmineMonitoring
  class MonitoringNotifyJob < ActiveJob::Base
    queue_as :default

    def perform(error_id)
      RedmineMonitoring::Notifications::Dispatcher.new.call(error_id)
    end
  end
end
