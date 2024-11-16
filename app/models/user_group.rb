# == Schema Information
#
# Table name: groups
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  tenant_id  :integer          not null
#  group_type :enum
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  type       :string           not null
#

class UserGroup < Group
  def signed_by_tag
    tenant.signed_by_tags.find_tag_containing_group(self)
  end

  def signature_requested_from_tag
    tenant.signature_requested_from_tags.find_tag_containing_group(self)
  end
end
