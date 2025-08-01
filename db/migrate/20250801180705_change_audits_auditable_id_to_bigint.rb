class ChangeAuditsAuditableIdToBigint < ActiveRecord::Migration[8.0]
  def up
    change_column :audits, :auditable_id, :bigint
  end

  def down
    # NOTE: Not needed
  end
end
