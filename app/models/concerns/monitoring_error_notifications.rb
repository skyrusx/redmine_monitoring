# frozen_string_literal: true

module MonitoringErrorNotifications
  extend ActiveSupport::Concern

  # Позволяет точечно отключить нотификации:
  # MonitoringError.create!(..., skip_notifications: true)
  attr_accessor :skip_notifications

  private

  def enqueue_notification
    return if skip_notifications
    return unless notify_enabled?

    # Через фон — чтобы не блокировать поток/страницу
    if defined?(RedmineMonitoring::MonitoringNotifyJob) && !RedmineMonitoring::Env.dev_mode?
      RedmineMonitoring::MonitoringNotifyJob.perform_later(id)
    else
      # Fallback на прямой вызов, если джоба недоступна
      RedmineMonitoring::Notifications::Dispatcher.new.call(id)
    end
  rescue StandardError => e
    Rails.logger.error "[Monitoring][notify] enqueue failed for error_id=#{id}: #{e.class} #{e.message}"
  end

  def notify_enabled?
    settings = Setting.plugin_redmine_monitoring || {}
    ActiveModel::Type::Boolean.new.cast(settings['notify_enabled'])
  end
end
