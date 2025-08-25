Redmine::Plugin.register :redmine_monitoring do
  name 'Redmine Monitoring plugin'
  author 'Ruslan Fedotov'
  description 'Error & performance monitoring'
  version '0.0.2'
  url 'https://github.com/skyrusx/redmine_monitoring'
  author_url 'https://github.com/skyrusx/'

  settings partial: 'settings/monitoring_settings', default: {
    enabled: true,
    dev_mode: false,
    max_errors: 10_000
  }
end

Rails.application.config.middleware.use RedmineMonitoring::Middleware
