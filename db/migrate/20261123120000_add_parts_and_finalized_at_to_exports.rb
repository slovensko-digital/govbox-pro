# frozen_string_literal: true

class AddPartsAndFinalizedAtToExports < ActiveRecord::Migration[8.1]
  def change
    change_table :exports, bulk: true do |t|
      t.column :parts, :jsonb, default: {}, null: false
      t.column :finalized_at, :datetime
    end
  end
end
