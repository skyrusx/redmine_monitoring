require_relative 'lib/redmine_monitoring/constants'

Redmine::Plugin.register :redmine_monitoring do
  name 'Redmine Monitoring plugin'
  author 'Ruslan Fedotov'
  description 'Error & performance monitoring'
  version '0.0.6'
  url 'https://github.com/skyrusx/redmine_monitoring'
  author_url 'https://github.com/skyrusx/'

  settings partial: 'settings/monitoring_settings', default: {
    enabled: true,
    dev_mode: false,
    max_errors: 10_000,
    retention_days: 90,
    log_levels: %w[fatal error warning info]
  }
end

Rails.application.config.middleware.use RedmineMonitoring::Middleware
