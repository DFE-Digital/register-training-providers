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

    # Remove the old unique index on uuid column (will be redundant with PRIMARY KEY)
    remove_index :users, :uuid

    # Rename uuid column to id and make it the primary key
    rename_column :users, :uuid, :id # rubocop:disable Rails/DangerousColumnNames
    execute "ALTER TABLE users ADD PRIMARY KEY (id)"

    # Add NOT NULL constraint to the foreign key column
    change_column_null :temporary_records, :created_by, false

    # Re-add the foreign key constraint
    add_foreign_key :temporary_records, :users, column: :created_by, primary_key: :id

    # Add the missing unique index that should have been there from the beginning
    # This composite index also serves as an index for created_by column queries
    add_index :temporary_records,
              [:created_by, :record_type, :purpose], unique: true,
                                                     name: "index_temporary_records_on_created_by_record_type_purpose"
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Cannot revert user UUID primary key migration"
  end
end
