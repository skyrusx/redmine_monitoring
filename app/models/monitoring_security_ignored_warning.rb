# frozen_string_literal: true

class MonitoringSecurityIgnoredWarning < ActiveRecord::Base
  belongs_to :monitoring_security_scan
  validates :warning_type, :fingerprint, :check_name, :message, :file, presence: true
end
