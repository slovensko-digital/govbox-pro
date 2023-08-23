class Group < ApplicationRecord
  belongs_to :tenant
  has_many :group_memberships, dependent: :destroy
  has_many :users, through: :group_memberships
  has_many :tag_groups, dependent: :destroy
  has_many :tags, through: :tag_groups

  validates_presence_of :name
  validates_uniqueness_of :name, scope: :tenant_id
  validates :group_type, inclusion: { in: ['ALL', 'USER', 'ADMIN', 'CUSTOM'], allow_blank: false }

  def is_modifiable?
    !group_type.in? %w[ALL USER]
  end
end
