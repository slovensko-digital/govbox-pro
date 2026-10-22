# frozen_string_literal: true

class AddCommonScopeToFilters < ActiveRecord::Migration[7.1]
  def up
    add_column :filters, :common, :boolean, null: false, default: false
    change_column_null :filters, :author_id, true
    # Existing filters were already visible to the entire tenant. Keep their IDs
    # and subscription associations; authorship becomes attribution, not access.
    execute "UPDATE filters SET common = TRUE"
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Retain common filters and their subscriptions"
  end
end
