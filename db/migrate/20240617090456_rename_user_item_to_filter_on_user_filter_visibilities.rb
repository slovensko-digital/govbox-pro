class RenameUserItemToFilterOnUserFilterVisibilities < ActiveRecord::Migration[7.1]
  def change
    add_reference :user_filter_visibilities, :filter, foreign_key: true, null: true

    reversible do |dir|
      dir.up do
        UserFilterVisibility.reset_column_information
        UserFilterVisibility.find_each do |visibility|
          if visibility.user_item_type == 'Filter'
            visibility.update!(filter_id: visibility.user_item_id)
          else
            visibility.destroy!
          end
        end
      end

      dir.down do
        UserFilterVisibility.reset_column_information
        UserFilterVisibility.find_each do |visibility|
          visibility.update!(user_item_id: visibility.filter_id, user_item_type: visibility.filter.class.name)
        end
      end
    end

    change_column_null :user_filter_visibilities, :filter_id, false
    remove_reference :user_filter_visibilities, :user_item, polymorphic: true, index: true
  end
end
