# == Schema Information
#
# Table name: groups
#
#  id         :bigint           not null, primary key
#  group_type :enum
#  name       :string           not null
#  type       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  tenant_id  :bigint           not null
#
class Group < ApplicationRecord
  include AuditableEvents

  belongs_to :tenant
  has_many :group_memberships, dependent: :destroy
  has_many :users, through: :group_memberships
  has_many :tag_groups, dependent: :destroy
  has_many :tags, through: :tag_groups
  has_many :box_groups, dependent: :destroy
  has_many :boxes, through: :box_groups

  EDITABLE_GROUP_TYPES = %w[AdminGroup SignerGroup CustomGroup]

  scope :editable, -> { where(type: EDITABLE_GROUP_TYPES) }

  validates_presence_of :name
  validates_uniqueness_of :name, scope: :tenant_id

  def editable?
    type.in? EDITABLE_GROUP_TYPES
  end

  def system?
    !is_a?(CustomGroup)
  end

  def destroyable?
    !system?
  end

  def renamable?
    !system?
  end
end
