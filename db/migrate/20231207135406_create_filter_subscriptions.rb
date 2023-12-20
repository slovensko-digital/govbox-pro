class CreateFilterSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :filter_subscriptions do |t|
      t.belongs_to :tenant, null: false, foreign_key: true
      t.belongs_to :user, null: false, foreign_key: true
      t.belongs_to :filter, null: false, foreign_key: true
      t.datetime :last_notify_run_at
      t.string :events, array: true, null: false, default: []

      t.timestamps
    end
  end
end
