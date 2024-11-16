# == Schema Information
#
# Table name: message_relations
#
#  id                 :integer          not null, primary key
#  message_id         :integer
#  related_message_id :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

class MessageRelation < ApplicationRecord
  belongs_to :message
  belongs_to :related_message, class_name: 'Message'
end
