class UserHiddenItems < ActiveRecord::Migration[7.1]
  def change
    create_table :user_hidden_items do |t|
      t.references :user, null: false, foreign_key: true
      t.string :user_hideable_type, null: false
      t.bigint :user_hideable_id
      t.timestamps
    end
  end
end
