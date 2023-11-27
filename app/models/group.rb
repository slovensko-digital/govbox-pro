# == Schema Information
#
# Table name: groups
#
#  id         :bigint           not null, primary key
#  group_type :enum             not null
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  tenant_id  :bigint           not null
#
class Group < ApplicationRecord
  belongs_to :tenant
  has_many :group_memberships, dependent: :destroy
  has_many :users, through: :group_memberships
  has_many :tag_groups, dependent: :destroy
  has_many :tags, through: :tag_groups

  ALL_TYPE = 'ALL'
  USER_TYPE = 'USER'
  ADMIN_TYPE = 'ADMIN'
  CUSTOM_TYPE = 'CUSTOM'
  SIGNING_TYPE = 'SIGNING'

  scope :fixed, -> { where(group_type: %w[ALL USER]) }
  scope :modifiable, -> { where.not(group_type: %w[ALL USER]) }

  validates_presence_of :name
  validates_uniqueness_of :name, scope: :tenant_id
  validates :group_type, inclusion: { in: [ALL_TYPE, USER_TYPE, ADMIN_TYPE, CUSTOM_TYPE, SIGNING_TYPE], allow_blank: false }

  def modifiable?
    !group_type.in? [ALL_TYPE, USER_TYPE]
  end

  def fixed?
    !modifiable?
  end

  def system?
    group_type != CUSTOM_TYPE
  end

  def destroyable?
    !system?
  end
end
