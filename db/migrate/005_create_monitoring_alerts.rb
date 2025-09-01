class CreateMonitoringAlerts < ActiveRecord::Migration[5.2]
  def change
    create_table :monitoring_alerts do |t|
      t.string :fingerprint, null: false
      t.integer :first_error_id, null: false
      t.integer :last_error_id, null: false
      t.integer :errors_count, default: 1, null: false
      t.datetime :first_seen_at, null: false
      t.datetime :last_seen_at, null: false
      t.integer :last_notified_count, default: 0, null: false
      t.datetime :window_started_at, null: false
      t.timestamps
    end

    add_index :monitoring_alerts, :fingerprint
  end
end
