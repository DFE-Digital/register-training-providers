class RenameEmailAddressToEmailOnContacts < ActiveRecord::Migration[8.0]
  def change
    rename_column :contacts, :email_address, :email
  end
end
