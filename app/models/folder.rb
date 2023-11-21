# == Schema Information
#
# Table name: folders
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  box_id     :bigint           not null
#
class Folder < ApplicationRecord
  belongs_to :box
  has_many :message_threads, dependent: :destroy

  delegate :tenant, to: :box
end
