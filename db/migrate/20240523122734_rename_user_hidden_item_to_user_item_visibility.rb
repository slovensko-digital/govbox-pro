class RenameUserHiddenItemToUserItemVisibility < ActiveRecord::Migration[7.1]
  def change
    rename_table :user_hidden_items, :user_item_visibilities
  end
end
