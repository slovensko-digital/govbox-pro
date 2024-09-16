# == Schema Information
#
# Table name: filters
#
#  id         :bigint           not null, primary key
#  icon       :string
#  is_pinned  :boolean          default(FALSE), not null
#  name       :string           not null
#  position   :integer          not null
#  query      :string
#  type       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  author_id  :bigint
#  tag_id     :bigint
#  tenant_id  :bigint           not null
#
class Filter < ApplicationRecord
  include AuditableEvents
  include Iconized

  belongs_to :author, class_name: 'User', optional: true
  belongs_to :tenant
  belongs_to :tag, optional: true
  has_many :user_filter_visibilities, inverse_of: :filter, dependent: :destroy

  validates :tenant_id, :name, presence: true

  before_create :fill_position

  scope :pinned, -> { where(is_pinned: true) }
  scope :not_pinned, -> { where(is_pinned: false) }
  scope :visible_for, -> (user) { joins(:user_filter_visibilities)
    .where(user_filter_visibilities: { visible: true, user: user})
    .where(is_pinned: false) }

  acts_as_list scope: :tenant_id

  def fill_position
    return if position.present?

    max_position = Filter.where(tenant_id: tenant_id).maximum(:position)

    self.position = (max_position || 0) + 1
  end
end
