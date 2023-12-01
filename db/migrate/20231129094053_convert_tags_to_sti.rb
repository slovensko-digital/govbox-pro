class ConvertTagsToSti < ActiveRecord::Migration[7.0]
  def up
    add_column :tags, :type, :string, null: true

    Tag.find_each do |tag|
      changes = if tag.system_name == "draft"
                  {
                    type: "DraftTag",
                    name: "Rozpracované",
                    system_name: nil
                  }
                elsif tag.system_name == "delivery_notification"
                  {
                    type: "Upvs::DeliveryNotificationTag",
                    name: "Na prevzatie",
                    system_name: nil
                  }
                else
                  {
                    type: "SimpleTag"
                  }
                end

      tag.update_columns(changes)
    end

    change_column_null :tags, :type, false
  end

  def down
    Tag.find_each do |tag|
      changes = if tag.type == "DraftTag"
                  {
                    system_name: "draft"
                  }
                elsif tag.type == "Upvs::DeliveryNotificationTag"
                  {
                    system_name: "delivery_notification"
                  }
                elsif tag.system_name.present?
                  {
                    external: true
                  }
                end

      tag.update_columns(changes)
    end

    remove_column :tags, :type
  end
end
