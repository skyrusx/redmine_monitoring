require_relative 'lib/redmine_monitoring/env'
require_relative 'lib/redmine_monitoring/constants'
require_relative 'lib/redmine_monitoring/request_subscriber'
require_relative 'lib/redmine_monitoring/bullet_integration'

default_settings = RedmineMonitoring::Constants::DEFAULT_SETTINGS

Redmine::Plugin.register :redmine_monitoring do
  name 'Redmine Monitoring plugin'
  author 'Ruslan Fedotov'
  description 'Error & performance monitoring'
  version '0.1.0'
  url 'https://github.com/skyrusx/redmine_monitoring'
  author_url 'https://github.com/skyrusx/'

  settings partial: 'settings/monitoring_settings', default: {
    enabled: default_settings[:enabled],
    dev_mode: default_settings[:dev_mode],
    max_errors: default_settings[:max_errors],
    retention_days: default_settings[:retention_days],
    log_levels: default_settings[:log_levels],
    enabled_formats: default_settings[:enabled_formats],
    enable_metrics: default_settings[:enable_metrics],
    slow_request_threshold_ms: default_settings[:slow_request_threshold_ms],
    notify_enabled: default_settings[:notify_enabled],
    notify_channels: default_settings[:notify_channels],
    notify_severity_min: default_settings[:notify_severity_min],
    notify_formats: default_settings[:notify_formats],
    notify_email_recipients: default_settings[:notify_email_recipients],
    notify_telegram_bot_token: default_settings[:notify_telegram_bot_token],
    notify_telegram_chat_ids: default_settings[:notify_telegram_chat_ids],
    notify_include_backtrace_lines: default_settings[:notify_include_backtrace_lines],
    notify_grouping_window_sec: default_settings[:notify_grouping_window_sec],
    notify_throttle_per_group_per_min: default_settings[:notify_throttle_per_group_per_min],
    security_enabled: default_settings[:security_enabled],
    security_allow_manual_scan: default_settings[:security_allow_manual_scan],
    security_keep_html: default_settings[:security_keep_html]
  }
end

Rails.application.config.middleware.insert_before Bullet::Rack, RedmineMonitoring::Middleware
RedmineMonitoring::RequestSubscriber.attach!
RedmineMonitoring::BulletIntegration.attach!
