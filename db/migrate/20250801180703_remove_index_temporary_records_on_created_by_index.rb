class RemoveIndexTemporaryRecordsOnCreatedByIndex < ActiveRecord::Migration[8.0]
  def up
    remove_index "temporary_records", name: "index_temporary_records_on_created_by"
  end

  def down
    # NOTE: Not needed
  end
end
