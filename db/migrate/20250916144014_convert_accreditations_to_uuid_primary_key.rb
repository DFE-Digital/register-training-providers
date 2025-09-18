class ConvertAccreditationsToUuidPrimaryKey < ActiveRecord::Migration[8.0]
  def change
    # Remove the existing primary key constraint on accreditations
    execute "ALTER TABLE accreditations DROP CONSTRAINT accreditations_pkey"

    # Drop the old bigint id column
    remove_column :accreditations, :id

    # Add default UUID generation to the uuid column (it currently has none)
    change_column_default :accreditations, :uuid, -> { "gen_random_uuid()" }

    # Rename uuid column to id and make it the primary key
    rename_column :accreditations, :uuid, :id
    execute "ALTER TABLE accreditations ADD PRIMARY KEY (id)"
  end
end
