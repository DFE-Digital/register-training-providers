class ChangeCodeToCitextOnProviders < ActiveRecord::Migration[8.0]
  def up
    begin
      remove_index :providers, name: "index_providers_on_code"
    rescue StandardError
      nil
    end

    enable_extension "citext"
    change_column :providers, :code, :citext
    add_index :providers, :code, unique: true
  end

  def down
    # NOTE: Not needed
  end
end
