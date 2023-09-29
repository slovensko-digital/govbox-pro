class GiveAdminsAccessToAllTags < ActiveRecord::Migration[7.0]
  def change
    Tag.find_each do |tag|
      admin_groups = tag.tenant.groups.where(group_type: "ADMIN")
      tag.groups += admin_groups
    end
  end
end
