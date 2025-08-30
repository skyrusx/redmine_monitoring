class CreateMonitoringErrors < ActiveRecord::Migration[5.2]
  def change
    create_table :monitoring_errors do |table|
      add_request_columns(table)
      table.timestamps
    end

    add_request_indexes
  end

  private

  def add_request_columns(table)
    table.string :exception_class
    table.string :error_class
    table.text :message
    table.text :backtrace
    table.string :severity
    table.string :controller_name
    table.string :action_name
    table.string :file
    table.integer :line
    table.integer :status_code
    table.string :format
    table.string :ip_address
    table.string :user_agent
    table.string :referer
    table.text :params
    table.text :headers
    table.text :env
    table.references :user, foreign_key: true, index: true, null: true
  end

  def add_request_indexes
    add_index :monitoring_errors, :created_at
    add_index :monitoring_errors, :exception_class
    add_index :monitoring_errors, :controller_name
    add_index :monitoring_errors, :action_name
    add_index :monitoring_errors, :status_code
  end
end
