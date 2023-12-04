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
  def name
    I18n.t("group.names.signer")
  end

  def self.user_added_to_group(signer_group, user)
    tag = signer_group.tenant.signature_requested_to_tags.find_or_initialize_by(user_id: user.id)
    tag.name = "Na podpis - #{user.name}"
    tag.visible = true
    tag.save!

    tag = signer_group.tenant.signed_by_tags.find_or_initialize_by(user_id: user.id)
    tag.name = "Podpisané - #{user.name}"
    tag.visible = true
    tag.save!
  end

  def self.user_removed_from_group(signer_group, user)
    signer_group.tenant.signature_requested_to_tags.where(user_id: user.id).destroy_all
  end
end
