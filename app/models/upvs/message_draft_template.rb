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
class Upvs::MessageDraftTemplate < ::MessageDraftTemplate
  def recipients
    # TODO load from DB
    [
      ['Test OVM 83136952', 'ico://sk/83136952'],
      ['Test OVM 83369721', 'ico://sk/83369721'],
      ['Test OVM 83369722', 'ico://sk/83369722'],
      ['Test OVM 83369723', 'ico://sk/83369723']
    ]
  end
end
