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

  def group_membership_modifiable?
    # can't be removed from default groups - "TENANT_NAME"_ALL group and named user default group "USER_NAME"_USER
    !group.group_type.in? ['ALL', 'USER']
  end
end
