class AllowNullForTelephoneNumberOnContacts < ActiveRecord::Migration[8.0]
  def change
    change_column_null :contacts, :telephone_number, true
  end
end
