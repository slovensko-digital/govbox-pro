# == Schema Information
#
# Table name: message_templates
#
#  id         :bigint           not null, primary key
#  content    :text             not null
#  metadata   :jsonb
#  name       :string           not null
#  system     :boolean          default(FALSE), not null
#  type       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  tenant_id  :bigint
#
class MessageTemplate < ApplicationRecord
  belongs_to :tenant, optional: true

  scope :global, -> { where(tenant_id: nil) }
  scope :system, -> { where(system: true) }

  def recipients
    '*'
  end

  def create_message(message, author:, box:, recipient_uri:)
    raise NotImplementedError
  end

  def create_message_reply(message, original_message:, author:)
    raise NotImplementedError
  end

  def build_message_from_template(message)
    raise NotImplementedError
  end

  def self.reply_template
    # TODO co ak ich bude viac, v roznych domenach? (napr. UPVS aj core)
    MessageTemplate.find_by!(
      system: true,
      name: 'Message reply'
    )
  end

  def self.tenant_templates_list(tenant)
    template_ids = MessageTemplate.where("system = FALSE AND (tenant_id = #{tenant.id} OR tenant_id IS NULL)").select('distinct on (metadata) *').map(&:id)
    MessageTemplate.where(id: template_ids).pluck(:name, :id)
  end
end
