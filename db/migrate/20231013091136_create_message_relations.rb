class CreateMessageRelations < ActiveRecord::Migration[7.0]
  def change
    create_table :message_relations do |t|
      t.references :message, index: true, foreign_key: { to_table: :messages }
      t.references :related_message, index: true, foreign_key: { to_table: :messages }
      t.string :relation_type, null: false

      t.timestamps
    end
  end
end
