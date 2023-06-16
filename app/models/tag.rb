# == Schema Information
#
# Table name: tags
#
#  id                                          :integer          not null, primary key
#  box_id                                      :integer
#  name                                        :string
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Tag < ApplicationRecord
  belongs_to :box
  has_and_belongs_to_many :message_threads

  delegate :tenant, to: :box
end
