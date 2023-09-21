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
  has_and_belongs_to_many :messages
  has_and_belongs_to_many :message_threads
  has_many :tag_users, dependent: :destroy
  has_many :users, through: :tag_users
  has_many :tag_groups, dependent: :destroy
  has_many :groups, through: :tag_groups
  belongs_to :owner, class_name: 'User', optional: true

  validates :name, presence: true
  validates :name, uniqueness: { scope: :tenant_id, case_sensitive: false }

  INBOX_TAG_NAME = 'Inbox'

  after_update_commit ->(tag) { EventBus.publish(:tag_renamed, tag) if previous_changes.key?("name") }
  after_destroy ->(tag) { EventBus.publish(:tag_removed, tag) }

  def self.inbox_tag(tenant_id)
    where(tenant_id: tenant_id).find_by_name!(INBOX_TAG_NAME)
  end
end
