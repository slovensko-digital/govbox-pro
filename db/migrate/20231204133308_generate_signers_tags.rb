class GenerateSignersTags < ActiveRecord::Migration[7.0]
  def up
    SignerGroup.includes(group_memberships: [:group, :user]).find_each do |group|
      group.group_memberships.each do |group_membership|
        GroupMembership.create_signing_tags_for(group_membership)
      end
    end
  end

  def down
    SignatureRequestedFromTag.destroy_all
    SignedByTag.destroy_all
  end
end
