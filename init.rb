require_relative 'lib/redmine_monitoring/constants'
require_relative 'lib/redmine_monitoring/request_subscriber'

Redmine::Plugin.register :redmine_monitoring do
  name 'Redmine Monitoring plugin'
  author 'Ruslan Fedotov'
  description 'Error & performance monitoring'
  version '0.0.8'
  url 'https://github.com/skyrusx/redmine_monitoring'
  author_url 'https://github.com/skyrusx/'

  settings partial: 'settings/monitoring_settings', default: {
    enabled: true,
    dev_mode: false,
    max_errors: 10_000,
    retention_days: 90,
    log_levels: %w[fatal error warning],
    enabled_formats: %w[HTML JSON],
    enable_metrics: true,
    slow_request_threshold_ms: 0
  }
end

Rails.application.config.middleware.use RedmineMonitoring::Middleware
RedmineMonitoring::RequestSubscriber.attach!
