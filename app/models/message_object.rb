# == Schema Information
#
# Table name: message_objects
#
#  id                                          :integer          not null, primary key
#  name                                        :string           not null
#  encoding                                    :string           not null
#  mimetype                                    :string           not null
#  signed                                      :boolean
#  object_type                                 :string           not null
#  message_id                                  :datetime         not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class MessageObject < ApplicationRecord
  belongs_to :message
  has_one :message_object_datum
end
