# == Schema Information
#
# Table name: message_object_data
#
#  id                :integer          not null, primary key
#  message_object_id :integer          not null
#  blob              :binary           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class MessageObjectDatum < ApplicationRecord
  belongs_to :message_object

  after_save { NestedMessageObject.create_from_message_object(message_object) }
  after_save { message_object.message.update_html_visualization if message_object.form? }
end
