class CreateMonitoringRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :monitoring_requests do |table|
      add_request_columns(table)
      table.timestamps
    end

    add_request_indexes
  end

  private

  def add_request_columns(table)
    table.string :method
    table.text :path
    table.string :normalized_path
    table.string :controller_name
    table.string :action_name
    table.string :format
    table.integer :status_code
    table.integer :duration_ms
    table.integer :view_ms
    table.integer :db_ms
    table.bigint :bytes_sent
    table.string :ip_address
    table.text :user_agent
    table.text :referer
    table.string :env
    table.references :user, foreign_key: true, index: true, null: true
  end

  def add_request_indexes
    add_index :monitoring_requests, :created_at
    add_index :monitoring_requests, :status_code
    add_index :monitoring_requests, :duration_ms
    add_index :monitoring_requests, %i[controller_name action_name]
    add_index :monitoring_requests, :normalized_path
    add_index :monitoring_requests, %i[normalized_path created_at]
    add_index :monitoring_requests, %i[status_code created_at]
    add_index :monitoring_requests, :format
    add_index :monitoring_requests, :env
  end
end
