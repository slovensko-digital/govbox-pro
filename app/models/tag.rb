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
class Tag < ApplicationRecord
  include AuditableEvents
  include Colorized, Iconized

  belongs_to :tenant
  belongs_to :owner, class_name: 'User', optional: true
  has_many :tag_groups, dependent: :destroy
  has_many :groups, through: :tag_groups
  has_many :messages_tags, dependent: :destroy
  has_many :messages, through: :messages_tags
  has_many :message_threads_tags, dependent: :destroy
  has_many :message_threads, through: :message_threads_tags
  has_many :automation_actions, class_name: "Automation::Action", as: :action_object, dependent: :restrict_with_error
  has_many :message_objects_tags, dependent: :destroy
  has_many :message_objects, through: :message_objects_tags

  validates :name, presence: true
  validates :name, uniqueness: { scope: :tenant_id, case_sensitive: true }

  scope :simple, -> { where(type: SimpleTag.to_s) }
  scope :visible, -> { where(visible: true) }
  scope :signing_tags, -> { where(type: ["SignedTag", "SignedByTag", "SignatureRequestedTag", "SignatureRequestedFromTag"]) }
  scope :signed, -> { where(type: ["SignedTag", "SignedByTag", "SignedExternallyTag"]) }
  scope :signed_by, -> { where(type: "SignedByTag") }
  scope :signature_requesting, -> { where(type: "SignatureRequestedFromTag") }
  scope :signed_internally, -> { where(type: ["SignedTag", "SignedByTag"]) }
  scope :archived, -> { where(type: ArchivedTag.to_s) }

  after_update_commit ->(tag) { EventBus.publish(:tag_renamed, tag) if previous_changes.key?("name") }

  def assign_to_message_object(message_object)
    message_object.assign_tag(self)
  end

  def assign_to_thread(thread)
    thread.assign_tag(self)
  end

  def mark_readable_by_groups(groups)
    self.groups += groups
  end

  def gives_access?
    tag_groups_count.positive?
  end

  def destroyable?
    raise NotImplementedError
  end

  def self.find_tag_containing_group(group)
    includes(:groups).to_a.find { |tag| tag.groups.include?(group) }
  end
end
