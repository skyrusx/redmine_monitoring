# frozen_string_literal: true

require_dependency 'monitoring_security_scan_retention'

class MonitoringSecurityScan < ApplicationRecord
  has_many :monitoring_security_warnings, dependent: :destroy
  has_many :monitoring_security_ignored_warnings, dependent: :destroy
  has_many :monitoring_security_errors, dependent: :destroy
  has_many :monitoring_security_obsolete,
           dependent: :destroy,
           class_name: 'MonitoringSecurityObsolete'

  VALID_SOURCES = %w[brakeman].freeze

  before_validation :assign_json_defaults
  include MonitoringSecurityScanRetention

  validates :source, presence: true, inclusion: { in: VALID_SOURCES }

  def source_brakeman?
    source == 'brakeman'
  end

  def refresh_counts!
    update!(
      warnings_count: monitoring_security_warnings.size,
      ignored_warnings_count: monitoring_security_ignored_warnings.size,
      errors_count: monitoring_security_errors.size,
      obsolete_count: monitoring_security_obsolete.size
    )
  end

  # Отдаём импорт сервису
  def self.ingest_brakeman!(json:, html: nil, target_scan: nil)
    RedmineMonitoring::Security::BrakemanImporter.call(
      json: json,
      html: html,
      target_scan: target_scan
    )
  end

  private

  def assign_json_defaults
    self.checks_performed = [] if checks_performed.nil?
    self.scan_info = {} if scan_info.nil?
    self.raw_json = {} if raw_json.nil?
  end
end
