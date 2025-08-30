# frozen_string_literal: true

require_dependency 'monitoring_error_scopes'
require_dependency 'monitoring_error_settings'
require_dependency 'monitoring_error_severity'
require_dependency 'monitoring_error_formats'
require_dependency 'monitoring_error_fingerprint'
require_dependency 'monitoring_error_retention'

class MonitoringError < ApplicationRecord
  include RedmineMonitoring::Constants

  belongs_to :user, optional: true

  validates :error_class, presence: true
  validates :message, presence: true
  validates :severity, inclusion: { in: SEVERITIES }, allow_nil: true

  before_validation :assign_fingerprint, on: :create
  after_commit :enforce_max_errors, :enforce_retention, on: :create

  include MonitoringErrorScopes
  include MonitoringErrorSettings
  include MonitoringErrorSeverity
  include MonitoringErrorFormats
  include MonitoringErrorFingerprint
  include MonitoringErrorRetention
end
