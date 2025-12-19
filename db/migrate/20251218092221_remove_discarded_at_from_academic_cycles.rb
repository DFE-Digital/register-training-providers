class RemoveDiscardedAtFromAcademicCycles < ActiveRecord::Migration[8.1]
  def change
    remove_column :academic_cycles, :discarded_at, :datetime
  end
end
