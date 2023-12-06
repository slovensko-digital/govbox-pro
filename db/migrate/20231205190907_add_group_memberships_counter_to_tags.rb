class AddGroupMembershipsCounterToTags < ActiveRecord::Migration[7.0]
  def change
    add_column :tags, :tag_groups_count, :integer, null: false, default: 0
    Tag.find_each do |tag|
      Tag.reset_counters(tag.id, :tag_groups)
    end
  end
end
