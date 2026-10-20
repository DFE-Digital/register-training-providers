class ChangeAddressEffectiveEndDateType < ActiveRecord::Migration[8.1]
  def change
    remove_column :addresses, :effective_end_date, :date
    add_column :addresses, :effective_end_dates, :jsonb, default: {}
  end
end
