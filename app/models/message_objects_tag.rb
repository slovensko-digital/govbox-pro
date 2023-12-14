# == Schema Information
#
# Table name: message_objects_tags
#
#  id                :bigint           not null, primary key
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  message_object_id :bigint           not null
#  tag_id            :bigint           not null
#
class MessageObjectsTag < ApplicationRecord
  belongs_to :message_object
  belongs_to :tag
end
