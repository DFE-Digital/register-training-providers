class AddRoleToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :role, :string

    User.reset_column_information

    say_with_time "Assigning the REG role to internal users" do
      User.where(api_user: false).update_all(role: "reg")
    end
  end

  def down
    remove_column :users, :role
  end
end
