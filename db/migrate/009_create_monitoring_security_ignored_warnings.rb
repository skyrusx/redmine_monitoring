# frozen_string_literal: true

class CreateMonitoringSecurityIgnoredWarnings < ActiveRecord::Migration[5.2]
  def change
    create_table :monitoring_security_ignored_warnings do |table|
      add_request_columns(table)
      table.timestamps
    end

    add_request_indexes
  end

  private

  def add_request_columns(table)
    table.references :monitoring_security_scan, null: false, index: { name: 'idx_ms_iw_scan' }

    table.string :warning_type, null: false
    table.integer :warning_code
    table.string :fingerprint, null: false
    table.string :check_name, null: false
    table.text :message, null: false
    table.string :file, null: false
    table.integer :line
    table.string :link
    table.text :code
    table.jsonb :render_path, default: []
    table.jsonb :location, default: {}
    table.string :user_input
    table.string :confidence
    table.jsonb :cwe_ids, default: []
    table.text :note
  end

  def add_request_indexes
    add_index :monitoring_security_ignored_warnings,
              %i[monitoring_security_scan_id fingerprint],
              unique: true,
              name: 'idx_ms_iw_scan_fingerprint'

    add_index :monitoring_security_ignored_warnings,
              :warning_type,
              name: 'idx_ms_iw_type'

    add_index :monitoring_security_ignored_warnings,
              :check_name,
              name: 'idx_ms_iw_check'

    add_index :monitoring_security_ignored_warnings,
              :confidence,
              name: 'idx_ms_iw_conf'

    add_index :monitoring_security_ignored_warnings,
              :warning_code,
              name: 'idx_ms_iw_code'

    add_index :monitoring_security_ignored_warnings,
              :file,
              name: 'idx_ms_iw_file'
  end
end
