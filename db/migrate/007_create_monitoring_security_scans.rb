# frozen_string_literal: true

class CreateMonitoringSecurityScans < ActiveRecord::Migration[5.2]
  def change
    create_table :monitoring_security_scans do |table|
      add_request_columns(table)
      table.timestamps
    end

    add_request_indexes
  end

  private

  def add_request_columns(table)
    table.string :source, null: false, default: 'brakeman'
    table.string :app_path
    table.string :rails_version
    table.string :ruby_version
    table.string :scanner_version
    table.datetime :started_at
    table.datetime :ended_at
    table.decimal :duration, precision: 12, scale: 6
    table.integer :warnings_count, null: false, default: 0
    table.integer :ignored_warnings_count, null: false, default: 0
    table.integer :errors_count, null: false, default: 0
    table.integer :obsolete_count, null: false, default: 0
    table.jsonb :checks_performed, null: false, default: []
    table.jsonb :scan_info, null: false, default: {}
    table.jsonb :raw_json, null: false, default: {}
    table.text :raw_html
  end

  def add_request_indexes
    add_index :monitoring_security_scans, :source
    add_index :monitoring_security_scans, :started_at
  end
end
