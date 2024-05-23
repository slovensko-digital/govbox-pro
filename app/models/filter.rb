# == Schema Information
#
# Table name: filters
#
#  id         :bigint           not null, primary key
#  is_pinned  :boolean          default(FALSE), not null
#  name       :string           not null
#  position   :integer          not null
#  query      :string
#  type       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  author_id  :bigint           not null
#  tag_id     :bigint
#  tenant_id  :bigint           not null
#
class Filter < ApplicationRecord
  include AuditableEvents

  belongs_to :author, class_name: 'User'
  belongs_to :tenant
  has_many :user_item_visibilities, inverse_of: :user_item, dependent: :destroy

  validates :tenant_id, :author_id, :name, presence: true

  before_create :fill_position

  scope :pinned, -> { where(is_pinned: true) }
  scope :not_pinned, -> { where(is_pinned: false) }

  def fill_position
    return if position.present?

    max_position = Filter.where(tenant_id: tenant_id).maximum(:position)

    self.position = (max_position || 0) + 1
  end
end
