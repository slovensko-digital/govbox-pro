# == Schema Information
#
# Table name: message_draft_templates
#
#  id         :bigint           not null, primary key
#  content    :text             not null
#  metadata   :jsonb
#  name       :string           not null
#  system     :boolean
#  type       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  tenant_id  :bigint
#
class MessageDraftTemplate < ApplicationRecord
  belongs_to :tenant, optional: true

  scope :global, -> { where(tenant_id: nil) }
  scope :not_system, -> { where(system: false) }

  def recipients
    '*'
  end

  def create_message(message, author:, box:, recipient_uri:)
    raise NotImplementedError
  end

  def create_message_reply(message, original_message:, author:)
    raise NotImplementedError
  end

  def self.reply_template
    # TODO co ak ich bude viac, v roznych domenach? (napr. UPVS aj core)
    MessageDraftTemplate.find_by!(
      system: true,
      name: 'Message reply'
    )
  end

  def self.tenant_templates_list(tenant)
    MessageDraftTemplate.not_system.where(tenant_id: tenant.id).or(MessageDraftTemplate.global.not_system).pluck(:name, :id)
  end
end
