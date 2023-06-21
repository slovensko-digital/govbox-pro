class CreateMessageThreads < ActiveRecord::Migration[7.0]
  def change
    create_table :message_threads do |t|
      t.belongs_to :folder, null: false, foreign_key: true
      t.string :title, null: false
      t.string :original_title, null: false
      t.uuid :merge_uuids, array: true, default: [], null: false
      t.datetime :delivered_at, null: false

      t.timestamps
    end
  end
end
