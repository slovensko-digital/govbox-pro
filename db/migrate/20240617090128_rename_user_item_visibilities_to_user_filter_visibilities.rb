class RenameUserItemVisibilitiesToUserFilterVisibilities < ActiveRecord::Migration[7.1]
  def change
    rename_table :user_item_visibilities, :user_filter_visibilities
  end
end
