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
  belongs_to :tenant
  has_many :group_memberships, dependent: :destroy
  has_many :users, through: :group_memberships
  has_many :tag_groups, dependent: :destroy
  has_many :tags, through: :tag_groups

  scope :editable, -> { where.not(type: %w[GroupAll GroupUser]) }

  validates_presence_of :name
  validates_uniqueness_of :name, scope: :tenant_id

  def editable?
    type.in? %w[GroupAdmin GroupCustom GroupSigner]
  end

  def system?
    type != GroupCustom.to_s
  end

  def destroyable?
    !system?
  end
end
