class GenerateSignersTags < ActiveRecord::Migration[7.0]
  def up
    SignerGroup.includes(group_memberships: [:group, :user]).find_each do |group|
      group.group_memberships.each(&:create_signing_tags!)
    end
  end

  def down
    SignatureRequestedFromTag.destroy_all
    SignedByTag.destroy_all
  end
end
