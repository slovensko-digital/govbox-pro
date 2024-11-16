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

class CustomGroup < Group
end
