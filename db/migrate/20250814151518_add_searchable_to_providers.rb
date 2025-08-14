class AddSearchableToProviders < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    add_column :providers, :searchable, :tsvector
    add_index :providers, :searchable, using: :gin

    say_with_time "Populating searchable column" do
      Provider.find_each do |provider|
        provider.save!(validate: false)
      end
    end
  end

  def down
    remove_index :providers, :searchable
    remove_column :providers, :searchable
  end
end
