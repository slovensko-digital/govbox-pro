# == Schema Information
#
# Table name: tags
#
#  id                                          :integer          not null, primary key
#  tenant_id                                   :integer
#  name                                        :string
#  visible                                     :boolean          not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Tag < ApplicationRecord
  belongs_to :tenant
  has_and_belongs_to_many :messages
  has_and_belongs_to_many :message_threads
  has_many :tag_users, dependent: :destroy
  has_many :users, through: :tag_users
  belongs_to :owner, class_name: 'User', optional: true
 
end
