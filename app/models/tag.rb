# == Schema Information
#
# Table name: tags
#
#  id                                          :integer          not null, primary key
#  tenant_id                                   :integer
#  name                                        :string
#  visible                                     :boolean          not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Tag < ApplicationRecord
  belongs_to :tenant
  belongs_to :owner, class_name: 'User', optional: true, foreign_key: :user_id
  has_many :tag_groups, dependent: :destroy
  has_many :groups, through: :tag_groups
  has_many :messages_tags
  has_many :messages, through: :messages_tags
  has_many :message_threads_tags
  has_many :message_threads, through: :message_threads_tags
  has_many :automation_actions, as: :action_object

  validates :name, presence: true
  validates :name, uniqueness: { scope: :tenant_id, case_sensitive: false }

  scope :visible, -> { where(visible: true) }

  after_create_commit ->(tag) { tag.mark_readable_by_groups(tag.tenant.admin_groups) }
  after_update_commit ->(tag) { EventBus.publish(:tag_renamed, tag) if previous_changes.key?("name") }
  after_destroy ->(tag) { EventBus.publish(:tag_destroyed, tag) }

  def mark_readable_by_groups(groups)
    self.groups += groups
  end
end
