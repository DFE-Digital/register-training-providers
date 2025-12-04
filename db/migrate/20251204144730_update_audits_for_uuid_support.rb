class UpdateAuditsForUuidSupport < ActiveRecord::Migration[8.1]
  def up
    truncate_tables :audits

    change_table :audits, bulk: true do |t|
      t.remove :auditable_id
      t.remove :associated_id
      t.remove :user_id

      t.uuid :auditable_id
      t.uuid :associated_id
      t.uuid :user_id

      t.index [:auditable_type, :auditable_id, :version], name: "auditable_index"
      t.index [:associated_type, :associated_id], name: "associated_index"
      t.index [:user_id, :user_type], name: "user_index"
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
