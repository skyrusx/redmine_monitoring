# frozen_string_literal: true

class MonitoringSecurityWarning < ApplicationRecord
  belongs_to :monitoring_security_scan

  validates :warning_type, :fingerprint, :check_name, :message, :file, presence: true

  scope :by_type, ->(type) { where(warning_type: type) }
  scope :by_check, ->(name) { where(check_name: name) }
  scope :by_confidence, ->(level) { where(confidence: level) }
  scope :high, -> { where(confidence: 0) }
  scope :medium, -> { where(confidence: 1) }
  scope :weak, -> { where(confidence: 2) }
  scope :controllers, -> { where("COALESCE(file,'') ~* '(^|/)(plugins/[^/]+/)?app/controllers/'") }
  scope :models, -> { where("COALESCE(file,'') ~* '(^|/)(plugins/[^/]+/)?app/models/'") }
  scope :templates, lambda {
    where(
      "COALESCE(file,'') ~* '(^|/)(plugins/[^/]+/)?app/views/' " \
      'OR (render_path IS NOT NULL AND jsonb_array_length(render_path) > 0)'
    )
  }
end
