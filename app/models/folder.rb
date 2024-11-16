# == Schema Information
#
# Table name: folders
#
#  id         :integer          not null, primary key
#  box_id     :integer          not null
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Folder < ApplicationRecord
  belongs_to :box
  has_many :message_threads, dependent: :destroy

  delegate :tenant, to: :box
end
