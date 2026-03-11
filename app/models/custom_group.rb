# == Schema Information
#
# Table name: groups
#
#  id                   :bigint           not null, primary key
#  all_boxes_permission :boolean          default(FALSE), not null
#  group_type           :enum
#  name                 :string           not null
#  type                 :string           not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  tenant_id            :bigint           not null
#
class CustomGroup < Group
end
