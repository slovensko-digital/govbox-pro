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

  after_commit ->(message_threads_tag) { EventBus.publish(:message_thread_changed, message_threads_tag.message_thread) }
end
