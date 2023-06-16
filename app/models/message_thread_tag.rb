# == Schema Information
#
# Table name: message_thread_tag
#
#  id                                          :integer          not null, primary key
#  message_thread_id                           :integer          not null
#  tag_id                                      :integer          not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class MessageThreadTag < ApplicationRecord
  belongs_to :message_thread
  belongs_to :tag
end
