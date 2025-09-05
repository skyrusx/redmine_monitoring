# frozen_string_literal: true

class MonitoringSecurityObsolete < ApplicationRecord
  self.table_name = 'monitoring_security_obsolete'
  belongs_to :monitoring_security_scan
  validates :fingerprint, presence: true
end
