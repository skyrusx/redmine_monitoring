# frozen_string_literal: true

module RedmineMonitoring
  module Notifications
    module Channels
      class Email
        def self.deliver(payload)
          settings = Setting.plugin_redmine_monitoring || {}
          list = (settings['notify_email_recipients'] || '').split(/[,\s]+/).reject(&:blank?)
          if list.blank?
            RedmineMonitoring::OperationalLogger.once(:email_recipients_missing,
                                                      level: :warn,
                                                      message: 'email channel skipped: recipients missing')
          end
          return if list.blank?

          MonitoringNotifierMailer.alert(payload, list).deliver_later
        end
      end
    end
  end
end
