class CreateTemporaryRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :temporary_records do |t|
      t.string :record_type, null: false
      t.jsonb :data, null: false, default: {}
      t.integer :created_by, null: false, index: true
      t.datetime :expires_at, null: false
      t.string :purpose, null: false, default: 0

      t.timestamps
    end

    add_foreign_key :temporary_records, :users, column: :created_by
    add_index :temporary_records,
              %i[created_by record_type purpose],
              unique: true,
              name: "index_temp_records_on_creator_type_purpose"
    add_index :temporary_records, :expires_at
  end
end
