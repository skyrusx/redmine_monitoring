# frozen_string_literal: true

require_dependency 'monitoring_request_scopes'
require_dependency 'monitoring_request_settings'
require_dependency 'monitoring_request_normalize'
require_dependency 'monitoring_request_retention'

class MonitoringRequest < ApplicationRecord
  belongs_to :user, optional: true

  include MonitoringRequestScopes
  include MonitoringRequestSettings
  include MonitoringRequestNormalize
  include MonitoringRequestRetention
end
