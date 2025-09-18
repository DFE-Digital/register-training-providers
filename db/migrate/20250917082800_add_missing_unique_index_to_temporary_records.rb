class AddMissingUniqueIndexToTemporaryRecords < ActiveRecord::Migration[8.0]
  def change
    add_index :temporary_records, [:created_by, :record_type, :purpose], unique: true,
                                                                         name: "index_temporary_records_on_created_by_record_type_purpose"
  end
end
