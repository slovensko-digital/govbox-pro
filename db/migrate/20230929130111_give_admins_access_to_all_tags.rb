class GiveAdminsAccessToAllTags < ActiveRecord::Migration[7.0]
  def change
    Tag.find_each { |tag| tag.mark_readable_by_groups(tag.tenant.admin_groups) }
  end
end
