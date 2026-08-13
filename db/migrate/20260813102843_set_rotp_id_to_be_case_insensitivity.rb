class SetRotpIdToBeCaseInsensitivity < ActiveRecord::Migration[8.1]
  def up
    change_column :providers, :rotp_id, :citext
  end

  def down
    # NOTE: We don't want to revert this change.
  end
end
