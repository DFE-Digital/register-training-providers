class AddSourceToProviderChanges < ActiveRecord::Migration[8.1]
  def up
    add_column :provider_changes,
               :source,
               :string,
               null: false,
               default: "requested"

    add_index :provider_changes,
              [:provider_id, :attribute_name],
              unique: true,
              where: "source = 'baseline'",
              name: "index_provider_changes_on_baseline_per_attribute"
  end

  def down
    remove_index :provider_changes,
                 name: "index_provider_changes_on_baseline_per_attribute"

    remove_column :provider_changes, :source
  end
end
