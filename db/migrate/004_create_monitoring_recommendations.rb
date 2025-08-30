class CreateMonitoringRecommendations < ActiveRecord::Migration[5.2]
  def change
    create_table :monitoring_recommendations do |t|
      t.string :source, null: false, default: 'bullet'
      t.string :category, null: false, default: 'performance'
      t.string :kind, null: false
      t.string :message, null: false
      t.jsonb :details, null: false, default: {}
      t.string :controller_name
      t.string :action_name
      t.string :path
      t.integer :user_id
      t.string :fingerprint, null: false
      t.timestamps
    end

    add_index :monitoring_recommendations, :created_at
    add_index :monitoring_recommendations, :fingerprint
    add_index :monitoring_recommendations, %i[source kind]
  end
end
