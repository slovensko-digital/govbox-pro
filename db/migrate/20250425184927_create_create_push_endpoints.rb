class CreateCreatePushEndpoints < ActiveRecord::Migration[7.1]
  def change
    create_table :push_endpoints do |t|
      t.references :user, null: false, foreign_key: true
      t.string :endpoint
      t.string :p256dh
      t.string :auth

      t.timestamps
    end
  end
end
