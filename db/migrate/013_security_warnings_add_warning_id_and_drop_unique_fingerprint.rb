# frozen_string_literal: true

class SecurityWarningsAddWarningIdAndDropUniqueFingerprint < ActiveRecord::Migration[5.2]
  def up
    remove_index :monitoring_security_warnings, name: 'idx_msw_scan_fingerprint'
    remove_index :monitoring_security_ignored_warnings, name: 'idx_ms_iw_scan_fingerprint'

    add_index :monitoring_security_warnings,
              %i[monitoring_security_scan_id fingerprint],
              name: 'idx_msw_scan_fingerprint'

    add_index :monitoring_security_ignored_warnings,
              %i[monitoring_security_scan_id fingerprint],
              name: 'idx_ms_iw_scan_fingerprint'

    add_column :monitoring_security_warnings, :warning_id, :integer
    add_column :monitoring_security_ignored_warnings, :warning_id, :integer

    add_index :monitoring_security_warnings, :warning_id
    add_index :monitoring_security_ignored_warnings, :warning_id

    add_index :monitoring_security_warnings,
              %i[monitoring_security_scan_idwarning_id],
              name: 'idx_msw_scan_warning_id'

    add_index :monitoring_security_ignored_warnings,
              %i[monitoring_security_scan_id warning_id],
              name: 'idx_msiw_scan_warning_id'
  end

  def down
    remove_index :monitoring_security_warnings, name: 'idx_msw_scan_warning_id'
    remove_index :monitoring_security_ignored_warnings, name: 'idx_msiw_scan_warning_id'
    remove_index :monitoring_security_warnings, column: :warning_id
    remove_index :monitoring_security_ignored_warnings, column: :warning_id

    remove_column :monitoring_security_warnings, :warning_id
    remove_column :monitoring_security_ignored_warnings, :warning_id

    remove_index :monitoring_security_warnings, name: 'idx_msw_scan_fingerprint'
    remove_index :monitoring_security_ignored_warnings, name: 'idx_ms_iw_scan_fingerprint'

    add_index :monitoring_security_warnings,
              %i[monitoring_security_scan_id fingerprint],
              unique: true, name: 'idx_msw_scan_fingerprint'

    add_index :monitoring_security_ignored_warnings,
              %i[monitoring_security_scan_id fingerprint],
              unique: true, name: 'idx_ms_iw_scan_fingerprint'
  end
end
