class ConvertTagsToSti < ActiveRecord::Migration[7.0]
  def up
    add_column :tags, :type, :string, null: true

    Tag.find_each do |tag|
      type = if tag.system_name == "draft"
               "DraftTag"
             elsif tag.system_name == "delivery_notification"
               "DeliveryNotificationTag"
             elsif tag.external
               "ExternalTag"
             else
               "SimpleTag"
             end

      tag.update_column(:type, type)
    end

    change_column_null :tags, :type, false
  end

  def down
    remove_column :tags, :type
  end
end
