class CreateMessageThreadMergeIdentifiers < ActiveRecord::Migration[7.0]
  def change
    create_table :message_thread_merge_identifiers do |t|
      t.references :message_thread, null: false, foreign_key: true
      t.uuid :uuid, null: false

      t.timestamps
    end

    add_index :message_thread_merge_identifiers, :uuid, unique: true
  end
end
