# == Schema Information
#
# Table name: message_object_data
#
#  id                :bigint           not null, primary key
#  blob              :binary           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  message_object_id :bigint           not null
#
class MessageObjectDatum < ApplicationRecord
  belongs_to :message_object

  after_create_commit { EventBus.publish(:message_form_data_created, message_object.message) if message_object.form? }
  after_save_commit { NestedMessageObject.create_from_message_object(message_object) }
end
