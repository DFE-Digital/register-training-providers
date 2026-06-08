class AddLifecycleFieldsToProviders < ActiveRecord::Migration[8.1]
  def change
    change_table :providers, bulk: true do |t|
      t.date :onboarded_at
      t.date :first_active_at
      t.jsonb :inactive_periods, default: [], null: false
    end

    add_index :providers, :onboarded_at
    add_index :providers, :first_active_at
  end
end
