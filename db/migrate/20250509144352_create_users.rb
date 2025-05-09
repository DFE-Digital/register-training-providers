class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :dfe_sign_in_uid
      t.string :email
      t.string :first_name
      t.string :last_name
      t.datetime :last_signed_in_at
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :discarded_at
  end
end
