# frozen_string_literal: true

class CreateUserFilterVisibilities < ActiveRecord::Migration[7.1]
  def change
    create_table :user_filter_visibilities do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :filter, null: false, foreign_key: { on_delete: :cascade }
      t.boolean :visible, null: false, default: true
      t.integer :position, null: false
      t.timestamps
    end
    add_index :user_filter_visibilities, [:user_id, :filter_id], unique: true
    add_index :user_filter_visibilities, [:user_id, :position]
    add_check_constraint :user_filter_visibilities, "position > 0", name: "positive_user_filter_position"
  end
end
