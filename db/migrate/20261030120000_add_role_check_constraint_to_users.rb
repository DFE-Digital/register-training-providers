class AddRoleCheckConstraintToUsers < ActiveRecord::Migration[8.1]
  def up
    # The validated check lets SET NOT NULL skip a full table scan.
    add_check_constraint :users, "role IS NOT NULL", name: "users_role_required"
    change_column_null :users, :role, false
    remove_check_constraint :users, name: "users_role_required"
    add_check_constraint :users, "role IN ('reg', 'mr', 'bat', 'ro')", name: "users_role_is_known"
  end

  def down
    remove_check_constraint :users, name: "users_role_is_known"
    change_column_null :users, :role, true
  end
end
