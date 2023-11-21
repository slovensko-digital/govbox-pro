# == Schema Information
#
# Table name: messages_tags
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  message_id :bigint           not null
#  tag_id     :bigint           not null
#
class MessagesTag < ApplicationRecord
  belongs_to :message
  belongs_to :tag
end
