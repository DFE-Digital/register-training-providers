class ConvertUsersToUuidPrimaryKey < ActiveRecord::Migration[8.0]
  def up
    # Remove foreign key constraint from temporary_records to users
    remove_foreign_key :temporary_records, :users

    # First, update temporary_records.created_by to use UUID values before we change users
    add_column :temporary_records, :created_by_uuid, :uuid

    # Populate the new UUID column with the corresponding user UUIDs
    execute <<-SQL.squish
      UPDATE temporary_records
      SET created_by_uuid = users.uuid
      FROM users
      WHERE temporary_records.created_by = users.id
    SQL

    # Remove the old bigint created_by column
    remove_column :temporary_records, :created_by

    # Rename the UUID column to created_by
    rename_column :temporary_records, :created_by_uuid, :created_by

    # Now convert users table to use UUID as primary key
    # Remove the existing primary key constraint on users
    execute "ALTER TABLE users DROP CONSTRAINT users_pkey"

    # Drop the old bigint id column
    remove_column :users, :id

    # Rename uuid column to id and make it the primary key
    rename_column :users, :uuid, :id # rubocop:disable Rails/DangerousColumnNames
    execute "ALTER TABLE users ADD PRIMARY KEY (id)"

    # Re-add the foreign key constraint
    add_foreign_key :temporary_records, :users, column: :created_by, primary_key: :id

    # Add index for the new foreign key
    add_index :temporary_records, :created_by
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Cannot revert user UUID primary key migration"
  end
end
