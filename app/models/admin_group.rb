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

class AdminGroup < Group
  def name
    I18n.t("group.names.admin")
  end
end
