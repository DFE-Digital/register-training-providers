class CreateAccreditations < ActiveRecord::Migration[8.0]
  def change
    create_table :accreditations do |t|
      t.references :provider, null: false, foreign_key: true
      t.string :number, null: false
      t.date :start_date, null: false
      t.date :end_date
      t.uuid :uuid, null: false

      t.timestamps
    end

    add_index :accreditations, :uuid, unique: true
    add_index :accreditations, :number
    add_index :accreditations, :start_date
    add_index :accreditations, :end_date
  end
end
