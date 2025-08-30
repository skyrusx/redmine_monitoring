require_relative 'lib/redmine_monitoring/constants'
require_relative 'lib/redmine_monitoring/request_subscriber'
require_relative 'lib/redmine_monitoring/bullet_integration'

default_settings = RedmineMonitoring::Constants::DEFAULT_SETTINGS

Redmine::Plugin.register :redmine_monitoring do
  name 'Redmine Monitoring plugin'
  author 'Ruslan Fedotov'
  description 'Error & performance monitoring'
  version '0.0.9'
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
    slow_request_threshold_ms: default_settings[:slow_request_threshold_ms]
  }
end

Rails.application.config.middleware.insert_before Bullet::Rack, RedmineMonitoring::Middleware
RedmineMonitoring::RequestSubscriber.attach!
RedmineMonitoring::BulletIntegration.attach!
