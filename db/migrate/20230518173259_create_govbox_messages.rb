class CreateGovboxMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :govbox_messages do |t|
      t.uuid :message_id, null: false
      t.uuid :correlation_id, null: false
      t.text :body, null: false

      t.timestamps
    end
  end
end
