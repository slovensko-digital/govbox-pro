class Filter < ApplicationRecord
  belongs_to :user

  validates :user_id, :name, :query, presence: true

  before_validation :fill_name_from_query
  before_create :fill_position

  def fill_name_from_query
    self.name = query unless name.present?

    true
  end

  def fill_position
    return if position.present?

    max_position = Filter.where(user_id: user_id).maximum(:position)

    self.position = (max_position || 0) + 1
  end
end
