class CreateMonitoringErrors < ActiveRecord::Migration[5.2]
  def change
    create_table :monitoring_errors do |t|
      t.string :exception_class
      t.string :error_class
      t.text :message
      t.text :backtrace
      t.string :severity
      t.string :controller_name
      t.string :action_name
      t.string :file
      t.integer :line
      t.integer :status_code
      t.string :format
      t.string :ip_address
      t.string :user_agent
      t.string :referer
      t.text :params
      t.text :headers
      t.text :env
      t.references :user, foreign_key: true, index: true, null: true
      t.timestamps
    end

    add_index :monitoring_errors, :created_at
    add_index :monitoring_errors, :exception_class
    add_index :monitoring_errors, :controller_name
    add_index :monitoring_errors, :action_name
    add_index :monitoring_errors, :status_code
  end
end
