class ChangeTemporaryRecordsCreatedByToBigint < ActiveRecord::Migration[8.0]
  def up
    change_column :temporary_records, :created_by, :bigint
  end

  def down
    # NOTE: not needed
  end
end
