class ConvertAccreditationsToUuidPrimaryKey < ActiveRecord::Migration[8.0]
  def up
    # Remove the existing primary key constraint on accreditations
    execute "ALTER TABLE accreditations DROP CONSTRAINT accreditations_pkey"

    # Perform column operations in bulk for better performance
    change_table :accreditations, bulk: true do |t|
      # Drop the old bigint id column
      t.remove :id

      # Add default UUID generation to the uuid column (it currently has none)
      t.change_default :uuid, -> { "gen_random_uuid()" }

      # Rename uuid column to id
      t.rename :uuid, :id # rubocop:disable Rails/DangerousColumnNames
    end

    # Add the new primary key constraint
    execute "ALTER TABLE accreditations ADD PRIMARY KEY (id)"
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Cannot revert accreditation UUID primary key migration"
  end
end
