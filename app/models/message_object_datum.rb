# == Schema Information
#
# Table name: message_object_datums
#
#  id                                          :integer          not null, primary key
#  blob                                        :binary           not null
#  message_object_id                           :integer          not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class MessageObjectDatum < ApplicationRecord
  belongs_to :message_object

  after_save_commit { NestedMessageObject.create_from_message_object(message_object) }
end
