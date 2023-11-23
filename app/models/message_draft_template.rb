# == Schema Information
#
# Table name: message_draft_templates
#
#  id         :bigint           not null, primary key
#  content    :text             not null
#  metadata   :jsonb
#  name       :string           not null
#  type       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  tenant_id  :bigint
#
class MessageDraftTemplate < ApplicationRecord
  belongs_to :tenant, optional: true

  def recipients
    '*'
  end

  def self.tenant_templates_list(tenant)
    MessageDraftTemplate.where(tenant_id: tenant.id).or(MessageDraftTemplate.where(tenant_id: nil)).pluck(:name, :id)
  end
end
