require_relative 'lib/redmine_monitoring/env'
require_relative 'lib/redmine_monitoring/constants'
require_relative 'lib/redmine_monitoring/request_subscriber'
require_relative 'lib/redmine_monitoring/bullet_integration'

RedmineMonitoring::Constants::MIME_TYPES.each do |format, mime_type|
  Mime::Type.register(mime_type, format) unless Mime::Type.lookup_by_extension(format)
end

Redmine::Plugin.register :redmine_monitoring do
  name 'Redmine Monitoring plugin'
  author 'Ruslan Fedotov'
  description 'Error & performance monitoring'
  version '0.2.0'
  url 'https://github.com/skyrusx/redmine_monitoring'
  author_url 'https://github.com/skyrusx/'

  settings partial: 'settings/monitoring_settings', default: RedmineMonitoring::Constants::DEFAULT_SETTINGS
end

Rails.application.config.middleware.use RedmineMonitoring::Middleware

RedmineMonitoring::RequestSubscriber.attach!
RedmineMonitoring::BulletIntegration.attach!
