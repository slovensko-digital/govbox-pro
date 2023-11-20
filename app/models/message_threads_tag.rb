# == Schema Information
#
# Table name: message_threads_tags
#
#  id                                          :integer          not null, primary key
#  message_thread_id                           :integer          not null
#  tag_id                                      :integer          not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class MessageThreadsTag < ApplicationRecord
  belongs_to :message_thread
  belongs_to :tag

  # used for joins only
  has_many :tag_groups, primary_key: :tag_id, foreign_key: :tag_id

  validates :tag_id, :message_thread_id, presence: true
  validates_uniqueness_of :tag_id, scope: :message_thread_id
  validate :thread_and_tag_tenants_matches

  scope :only_visible_tags, ->{ includes(:tag).joins(:tag).where("tags.visible = ?", true).order("tags.name") }

  after_commit ->(message_threads_tag) { EventBus.publish(:message_thread_tag_changed, message_threads_tag) }

  def thread_and_tag_tenants_matches
    unless message_thread.box.tenant == tag.tenant && tag.tenant
      errors.add :name, 'Unpermitted combination of tag and message thread'
    end
  end
end
