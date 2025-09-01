class CreateMonitoringAlertChannels < ActiveRecord::Migration[5.2]
  def change
    create_table :monitoring_alert_channels do |t|
      t.integer :monitoring_alert_id, null: false
      t.string :channel, null: false
      t.string :status, null: false, default: 'new'
      t.integer :sent_count, null: false, default: 0
      t.datetime :last_sent_at
      t.text :last_error
      t.timestamps
    end

    add_index :monitoring_alert_channels,
              %i[monitoring_alert_id channel],
              unique: true,
              name: 'idx_monitoring_alert_channels_unique'

    add_foreign_key :monitoring_alert_channels, :monitoring_alerts
  end
end
