class AddFingerprintToMonitoringErrors < ActiveRecord::Migration[5.2]
  def change
    add_column :monitoring_errors, :fingerprint, :string
    add_index :monitoring_errors, :fingerprint
  end
end
