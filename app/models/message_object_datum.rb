# == Schema Information
#
# Table name: message_object_datums
#
#  id                                          :integer          not null, primary key
#  title                                       :string           not null
#  original_title                              :string           not null
#  merge_uuids                                 :uuid             not null
#  delivered_at                                :datetime         not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class MessageObjectDatum < ApplicationRecord
  belongs_to :message_object
end
