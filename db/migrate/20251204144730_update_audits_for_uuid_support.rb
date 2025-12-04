class UpdateAuditsForUuidSupport < ActiveRecord::Migration[8.1]
  def up
    truncate_tables :audits

    remove_column :audits, :auditable_id
    remove_column :audits, :associated_id
    remove_column :audits, :user_id

    add_column :audits, :auditable_id, :uuid
    add_column :audits, :associated_id, :uuid
    add_column :audits, :user_id, :uuid

    add_index :audits, [:auditable_type, :auditable_id, :version], name: "auditable_index"
    add_index :audits, [:associated_type, :associated_id], name: "associated_index"
    add_index :audits, [:user_id, :user_type], name: "user_index"
  end

  def down
    truncate_tables :audits

    remove_column :audits, :auditable_id
    remove_column :audits, :associated_id
    remove_column :audits, :user_id

    add_column :audits, :auditable_id, :bigint
    add_column :audits, :associated_id, :integer
    add_column :audits, :user_id, :integer

    add_index :audits, [:auditable_type, :auditable_id, :version], name: "auditable_index"
    add_index :audits, [:associated_type, :associated_id], name: "associated_index"
    add_index :audits, [:user_id, :user_type], name: "user_index"
  end
end
