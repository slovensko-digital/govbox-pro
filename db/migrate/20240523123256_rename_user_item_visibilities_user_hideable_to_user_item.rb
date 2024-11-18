class RenameUserItemVisibilitiesUserHideableToUserItem < ActiveRecord::Migration[7.1]
  def change
    rename_column :user_item_visibilities, :user_hideable_type, :user_item_type
    rename_column :user_item_visibilities, :user_hideable_id, :user_item_id
  end
end
