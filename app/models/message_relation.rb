# == Schema Information
#
# Table name: message_relations
#
#  id                 :bigint           not null, primary key
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  message_id         :bigint
#  related_message_id :bigint
#
class MessageRelation < ApplicationRecord
  belongs_to :message
  belongs_to :related_message, class_name: 'Message'
end
