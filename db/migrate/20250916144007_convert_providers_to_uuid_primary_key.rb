class ConvertProvidersToUuidPrimaryKey < ActiveRecord::Migration[8.0]
  def change
    # Remove foreign key constraint from accreditations to providers
    remove_foreign_key :accreditations, :providers

    # First, update accreditations.provider_id to use UUID values before we change providers
    add_column :accreditations, :provider_uuid, :uuid

    # Populate the new UUID column with the corresponding provider UUIDs
    execute <<-SQL.squish
      UPDATE accreditations
      SET provider_uuid = providers.uuid
      FROM providers
      WHERE accreditations.provider_id = providers.id
    SQL

    # Remove the old bigint provider_id column
    remove_column :accreditations, :provider_id

    # Rename the UUID column to provider_id
    rename_column :accreditations, :provider_uuid, :provider_id

    # Now convert providers table to use UUID as primary key
    # Remove the existing primary key constraint on providers
    execute "ALTER TABLE providers DROP CONSTRAINT providers_pkey"

    # Drop the old bigint id column
    remove_column :providers, :id

    # Rename uuid column to id and make it the primary key
    rename_column :providers, :uuid, :id
    execute "ALTER TABLE providers ADD PRIMARY KEY (id)"

    # Re-add the foreign key constraint
    add_foreign_key :accreditations, :providers, column: :provider_id, primary_key: :id

    # Add index for the new foreign key
    add_index :accreditations, :provider_id
  end
end
