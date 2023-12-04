# == Schema Information
#
# Table name: group_memberships
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  group_id   :bigint           not null
#  user_id    :bigint           not null
#
class GroupMembership < ApplicationRecord
  include AuditableEvents

  belongs_to :group
  belongs_to :user

  after_create do |group_membership|
    if group_membership.group.is_a?(SignerGroup)
      SignerGroup.user_added_to_group(group_membership.group, group_membership.user)
    end
  end

  after_destroy do |group_membership|
    if group_membership.group.is_a?(SignerGroup)
      SignerGroup.user_removed_from_group(group_membership.group, group_membership.user)
    end
  end
end
