# == Schema Information
#
# Table name: message_objects_tags
#
#  id                :integer          not null, primary key
#  message_object_id :integer          not null
#  tag_id            :integer          not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class MessageObjectsTag < ApplicationRecord
  belongs_to :message_object
  belongs_to :tag
end
