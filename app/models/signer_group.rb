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
class SignerGroup < Group
  include TagCreation

  def name
    I18n.t("group.names.signer")
  end

  def signed_by_tag
    tenant.signed_by_tags.find_tag_containing_group(self)
  end

  def signature_requested_from_tag
    tenant.signature_requested_from_tags.find_tag_containing_group(self)
  end

  def create_signature_requested_tag!
    find_or_create_signing_tag(
      tags_scope: tenant.signature_requested_from_tags,
      user_group: self,
      tag_name: "Na podpis: #{name}",
      color: "yellow",
      icon: "pencil"
    )
  end
end
