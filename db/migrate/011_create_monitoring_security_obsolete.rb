# frozen_string_literal: true

class CreateMonitoringSecurityObsolete < ActiveRecord::Migration[5.2]
  def change
    create_table :monitoring_security_obsolete do |t|
      t.references :monitoring_security_scan, null: false, index: { name: 'idx_mso_scan' }
      t.string :fingerprint, null: false
      t.timestamps
    end

    add_index :monitoring_security_obsolete, %i[monitoring_security_scan_id fingerprint],
              unique: true, name: 'idx_mso_scan_fingerprint'
    add_index :monitoring_security_obsolete, :fingerprint, name: 'idx_mso_fingerprint'
  end
end
