# == Schema Information
#
# Table name: tags
#
#  id            :bigint           not null, primary key
#  external_name :string
#  name          :string           not null
#  type          :string           not null
#  visible       :boolean          default(TRUE), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  owner_id      :bigint
#  tenant_id     :bigint           not null
#
class Tag < ApplicationRecord
  include AuditableEvents

  belongs_to :tenant
  belongs_to :owner, class_name: 'User', optional: true
  has_many :tag_groups, dependent: :destroy
  has_many :groups, through: :tag_groups
  has_many :messages_tags, dependent: :destroy
  has_many :messages, through: :messages_tags
  has_many :message_threads_tags, dependent: :destroy
  has_many :message_threads, through: :message_threads_tags
  has_many :automation_actions, class_name: "Automation::Action", as: :action_object, dependent: :restrict_with_error

  validates :name, presence: true
  validates :name, uniqueness: { scope: :tenant_id, case_sensitive: false }

  scope :simple, -> { where(type: SimpleTag.to_s) }
  scope :visible, -> { where(visible: true) }

  after_create_commit ->(tag) { tag.mark_readable_by_groups([tag.tenant.admin_group]) }
  after_update_commit ->(tag) { EventBus.publish(:tag_renamed, tag) if previous_changes.key?("name") }

  def mark_readable_by_groups(groups)
    self.groups += groups
  end

  def destroyable?
    false
  end
end
