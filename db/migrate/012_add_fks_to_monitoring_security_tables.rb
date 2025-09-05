# frozen_string_literal: true

class AddFksToMonitoringSecurityTables < ActiveRecord::Migration[5.2]
  def change
    add_foreign_key :monitoring_security_warnings, :monitoring_security_scans,
                    column: :monitoring_security_scan_id, name: 'fk_msw_scan'
    add_foreign_key :monitoring_security_ignored_warnings, :monitoring_security_scans,
                    column: :monitoring_security_scan_id, name: 'fk_ms_iw_scan'
    add_foreign_key :monitoring_security_errors, :monitoring_security_scans,
                    column: :monitoring_security_scan_id, name: 'fk_mse_scan'
    add_foreign_key :monitoring_security_obsolete, :monitoring_security_scans,
                    column: :monitoring_security_scan_id, name: 'fk_mso_scan'
  end
end
