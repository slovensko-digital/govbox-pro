class Filter < ApplicationRecord
  belongs_to :author, class_name: 'User'
  belongs_to :tenant

  validates :tenant_id, :author_id, :name, :query, presence: true

  before_create :fill_position

  def fill_position
    return if position.present?

    max_position = Filter.where(tenant_id: tenant_id).maximum(:position)

    self.position = (max_position || 0) + 1
  end
end
