class CreateMonitoringRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :monitoring_requests do |t|
      t.string :method
      t.text :path
      t.string :normalized_path
      t.string :controller_name
      t.string :action_name
      t.string :format
      t.integer :status_code
      t.integer :duration_ms
      t.integer :view_ms
      t.integer :db_ms
      t.bigint :bytes_sent
      t.string :ip_address
      t.text :user_agent
      t.text :referer
      t.string :env
      t.references :user, foreign_key: true, index: true, null: true
      t.timestamps
    end

    add_index :monitoring_requests, :created_at
    add_index :monitoring_requests, :status_code
    add_index :monitoring_requests, :duration_ms
    add_index :monitoring_requests, [:controller_name, :action_name]
    add_index :monitoring_requests, :normalized_path
    add_index :monitoring_requests, [:normalized_path, :created_at]
    add_index :monitoring_requests, [:status_code, :created_at]
    add_index :monitoring_requests, :format
    add_index :monitoring_requests, :env
  end
end
