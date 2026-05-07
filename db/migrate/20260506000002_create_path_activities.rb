class CreatePathActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :path_activities, id: :uuid do |t|
      t.uuid    :onboarding_path_id, null: false
      t.string  :root_system
      t.string  :name
      t.text    :description
      t.integer :estimated_minutes
      t.integer :week_number
      t.integer :position

      t.timestamps null: false
    end

    add_index :path_activities, [:onboarding_path_id, :root_system, :position],
              name: "index_path_activities_on_path_root_position"
    add_index :path_activities, [:onboarding_path_id, :week_number],
              name: "index_path_activities_on_path_week"
    add_foreign_key :path_activities, :onboarding_paths
  end
end
