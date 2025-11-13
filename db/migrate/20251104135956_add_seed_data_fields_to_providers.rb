class AddSeedDataFieldsToProviders < ActiveRecord::Migration[8.0]
  def change
    change_table :providers, bulk: true do |t|
      t.boolean :seed_data_with_issues, default: false, null: false
      t.jsonb :seed_data_notes, default: {}, null: false
    end
  end
end
