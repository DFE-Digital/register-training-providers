class AddTypesAndEffectiveEndDateToAddresses < ActiveRecord::Migration[8.1]
  def change
    change_table :addresses, bulk: true do |t|
      t.string :types, array: true, default: []
      t.date :effective_end_date
    end
  end
end
