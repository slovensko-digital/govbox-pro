class CreateExports < ActiveRecord::Migration[7.1]
  def change
    create_table :exports do |t|
      t.belongs_to :user, null: false, foreign_key: true
      t.integer :message_thread_ids, array: true, null: false, default: []

      t.timestamps
    end
  end
end
