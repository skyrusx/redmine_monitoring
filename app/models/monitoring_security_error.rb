# frozen_string_literal: true

class MonitoringSecurityError < ApplicationRecord
  belongs_to :monitoring_security_scan
  validates :error, presence: true
end
