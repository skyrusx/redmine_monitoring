# frozen_string_literal: true

module RedmineMonitoring
  module Notifications
    module Channels
      class Email
        def self.deliver(payload)
          settings = Setting.plugin_redmine_monitoring || {}
          list = (settings['notify_email_recipients'] || '').split(/[,\s]+/).reject(&:blank?)
          return if list.blank?

          MonitoringNotifierMailer.alert(payload, list).deliver_later
        end
      end
    end
  end
end
