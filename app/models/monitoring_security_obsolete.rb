# frozen_string_literal: true

class MonitoringSecurityObsolete < ActiveRecord::Base
  self.table_name = 'monitoring_security_obsolete'
  belongs_to :monitoring_security_scan
  validates :fingerprint, presence: true
end
