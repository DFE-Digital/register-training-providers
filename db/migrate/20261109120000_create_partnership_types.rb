class CreatePartnershipTypes < ActiveRecord::Migration[8.1]
  def up
    create_table :partnership_types, id: :uuid do |t|
      t.references :partnership,
                   type: :uuid,
                   null: false,
                   index: false,
                   foreign_key: { on_delete: :cascade }

      t.string :partnership_type, null: false
      t.string :source, null: false, default: "user"
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :partnership_types,
              %i[partnership_id partnership_type],
              unique: true,
              where: "discarded_at IS NULL"

    backfill_recruitment_type
  end

  def down
    drop_table :partnership_types
  end

  def backfill_recruitment_type
    execute <<~SQL.squish
      INSERT INTO partnership_types (partnership_id, partnership_type, source, created_at, updated_at)
      SELECT partnerships.id, 'recruitment', 'backfill', now(), now()
      FROM partnerships
      ON CONFLICT (partnership_id, partnership_type) WHERE discarded_at IS NULL DO NOTHING
    SQL
  end
end
