class ChangePartnershipAcademicYearsToUuid < ActiveRecord::Migration[8.1]
  def up
    add_column :partnership_academic_years,
               :uuid_id,
               :uuid,
               default: "gen_random_uuid()",
               null: false

    execute <<~SQL.squish
      ALTER TABLE partnership_academic_years
      DROP CONSTRAINT partnership_academic_years_pkey;
    SQL

    remove_column :partnership_academic_years, :id
    rename_column :partnership_academic_years, :uuid_id, :id # rubocop:disable Rails/DangerousColumnNames

    execute <<~SQL.squish
      ALTER TABLE partnership_academic_years
      ADD PRIMARY KEY (id);
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Cannot revert partnership academic year UUID primary key migration"
  end
end
