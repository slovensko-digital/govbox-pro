class Group < ApplicationRecord
  belongs_to :tenant
  has_many :group_memberships, dependent: :destroy
  has_many :users, through: :group_memberships

  validates :group_type, inclusion: { in: ['ALL', 'USER', 'ADMIN', 'CUSTOM'], allow_blank: false}
end
