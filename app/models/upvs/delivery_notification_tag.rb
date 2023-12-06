# == Schema Information
#
# Table name: tags
#
#  id               :bigint           not null, primary key
#  color            :enum
#  external_name    :string
#  icon             :string
#  name             :string           not null
#  tag_groups_count :integer          default(0), not null
#  type             :string           not null
#  visible          :boolean          default(TRUE), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  owner_id         :bigint
#  tenant_id        :bigint           not null
#
class Upvs::DeliveryNotificationTag < ::Tag
  def self.find_or_create_for_tenant!(tenant)
    find_or_create_by!(
      type: self.to_s,
      tenant: tenant
    ) do |tag|
      tag.name = "Na prevzatie"
      tag.visible = true
    end
  end
end
