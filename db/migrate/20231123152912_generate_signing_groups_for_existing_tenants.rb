class GenerateSigningGroupsForExistingTenants < ActiveRecord::Migration[7.0]
  def up
    Tenant.find_each do |tenant|
      tenant.groups.create!(name: 'Podpisovatelia', group_type: Group::SIGNING_TYPE)
    end
  end

  def down
    Group.where(group_type: Group::SIGNING_TYPE).destroy_all
  end
end
