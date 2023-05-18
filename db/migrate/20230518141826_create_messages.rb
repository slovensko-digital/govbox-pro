class CreateMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :messages do |t|
      t.uuid :uuid, null: false
      t.belongs_to :message_thread, null: false, foreign_key: true
      t.string :title, null: false
      t.string :sender_name, null: false
      t.string :recipient_name, null: false
      t.datetime :delivered_at, null: false

      t.timestamps
    end
  end
end
