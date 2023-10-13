# == Schema Information
#
# Table name: message_threads
#
#  id                                          :integer          not null, primary key
#  title                                       :string           not null
#  original_title                              :string           not null
#  delivered_at                                :datetime         not null
#  last_message_delivered_at                   :datetime         not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class MessageThreadNote < ApplicationRecord
  belongs_to :message_thread
end
