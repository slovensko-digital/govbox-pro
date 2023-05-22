# == Schema Information
#
# Table name: users
#
#  id                                          :integer          not null, primary key
#  email                                       :string           not null
#  name                                        :string           not null
#  tenant_id                                   :integer
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class User < ApplicationRecord
  belongs_to :tenant
  has_many :group_memberships, dependent: :destroy
  has_many :groups, through: :group_memberships
end
