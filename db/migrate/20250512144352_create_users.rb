class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :dfe_sign_in_uid
      t.string :email, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.datetime :last_signed_in_at
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :discarded_at
  end
end
