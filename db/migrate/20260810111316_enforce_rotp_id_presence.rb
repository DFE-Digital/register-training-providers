class EnforceRotpIdPresence < ActiveRecord::Migration[8.1]
  def change
    change_column_null :providers, :rotp_id, false
  end
end
