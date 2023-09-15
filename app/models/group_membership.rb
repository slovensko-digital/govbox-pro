# == Schema Information
#
# Table name: group_memberships
#
#  id                                          :integer          not null, primary key
#  group_id                                    :integer          not null
#  user_id                                     :integer          not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class GroupMembership < ApplicationRecord
  belongs_to :group
  belongs_to :user

  def group_membership_modifiable?
    # can't be removed from default groups - "TENANT_NAME"_ALL group and named user default group "USER_NAME"_USER
    !group.group_type.in? ['ALL', 'USER'] 
  end
end
