# == Schema Information
#
# Table name: groups
#
#  id         :bigint           not null, primary key
#  group_type :enum
#  name       :string           not null
#  type       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  tenant_id  :bigint           not null
#
class AdminGroup < Group
  def name
    I18n.t("group.names.admin")
  end
end
