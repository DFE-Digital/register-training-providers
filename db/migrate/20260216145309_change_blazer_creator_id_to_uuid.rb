class ChangeBlazerCreatorIdToUuid < ActiveRecord::Migration[8.1]
  def up
    remove_index :blazer_queries, :creator_id if index_exists?(:blazer_queries, :creator_id)
    remove_index :blazer_dashboards, :creator_id if index_exists?(:blazer_dashboards, :creator_id)
    remove_index :blazer_checks, :creator_id if index_exists?(:blazer_checks, :creator_id)

    remove_column :blazer_queries, :creator_id
    remove_column :blazer_dashboards, :creator_id
    remove_column :blazer_checks, :creator_id

    add_column :blazer_queries, :creator_id, :uuid
    add_column :blazer_dashboards, :creator_id, :uuid
    add_column :blazer_checks, :creator_id, :uuid

    add_index :blazer_queries, :creator_id
    add_index :blazer_dashboards, :creator_id
    add_index :blazer_checks, :creator_id
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
