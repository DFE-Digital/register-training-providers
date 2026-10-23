class ChangeAddressEffectiveEndDateType < ActiveRecord::Migration[8.1]
  def change
    change_table :addresses, bulk: true do |t|
      t.remove :effective_end_date, type: :date
      t.column :effective_end_dates, :jsonb, default: {}
    end
  end
end
