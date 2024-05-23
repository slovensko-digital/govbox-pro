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
class SignatureRequestedFromTag < Tag
  def assign_to_thread(thread)
    super
    tenant.signature_requested_tag.assign_to_thread(thread)
  end

  def destroyable?
    false
  end
end
