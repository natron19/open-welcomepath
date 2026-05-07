class CreateOnboardingPaths < ActiveRecord::Migration[8.1]
  def change
    create_table :onboarding_paths, id: :uuid do |t|
      t.uuid    :user_id,           null: false
      t.string  :name
      t.string  :community_type
      t.string  :member_type
      t.text    :member_background
      t.text    :integration_goal
      t.text    :gemini_raw

      t.timestamps null: false
    end

    add_index :onboarding_paths, :user_id
    add_foreign_key :onboarding_paths, :users
  end
end
