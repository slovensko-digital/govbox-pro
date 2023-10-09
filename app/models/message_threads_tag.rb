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

  attr_accessor :tag_name, :tag_creation_params

  # used for joins only
  has_many :tag_groups, primary_key: :tag_id, foreign_key: :tag_id

  validates :tag_id, :message_thread_id, presence: true
  validate :thread_and_tag_tenants_matches

  before_validation :create_tag_from_tag_name

  after_commit ->(message_threads_tag) { EventBus.publish(:message_thread_tag_changed, message_threads_tag) }

  def create_tag_from_tag_name
    create_tag(tag_creation_params.merge(name: tag_name)) if tag_name.present?
  end

  def thread_and_tag_tenants_matches
    unless message_thread.folder.box.tenant == tag.tenant && tag.tenant
      errors.add :name, 'Unpermitted combination of tag and message thread'
    end
  end
end
