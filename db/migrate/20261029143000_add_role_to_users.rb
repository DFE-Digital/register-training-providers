class AddRoleToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :role, :string

    say_with_time "Assigning roles to existing users" do
      execute "UPDATE users SET role = 'reg' WHERE api_user = false"
      execute "UPDATE users SET role = 'ro' WHERE api_user = true"
    end

    execute "DELETE FROM temporary_records WHERE record_type = 'User'"
  end

  def down
    remove_column :users, :role
  end
end
