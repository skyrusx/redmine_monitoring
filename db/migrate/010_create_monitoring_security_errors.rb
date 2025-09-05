# frozen_string_literal: true

class CreateMonitoringSecurityErrors < ActiveRecord::Migration[5.2]
  def change
    create_table :monitoring_security_errors do |t|
      t.references :monitoring_security_scan, null: false, index: { name: 'idx_mse_scan' }

      t.text :error, null: false
      t.text :location
      t.jsonb :backtrace, default: []

      t.timestamps
    end

    add_index :monitoring_security_errors, :location, name: 'idx_mse_location'
  end
end
