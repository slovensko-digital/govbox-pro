# == Schema Information
#
# Table name: messages_tags
#
#  id         :integer          not null, primary key
#  message_id :integer          not null
#  tag_id     :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class MessagesTag < ApplicationRecord
  belongs_to :message
  belongs_to :tag
end
