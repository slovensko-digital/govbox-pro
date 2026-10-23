# frozen_string_literal: true

class UserFilterVisibility < ApplicationRecord
  belongs_to :user
  belongs_to :filter

  validates :filter_id, uniqueness: { scope: :user_id }
  validates :visible, inclusion: { in: [true, false] }
  validates :position, numericality: { only_integer: true, greater_than: 0 }
  validate :filter_available_to_user

  private

  def filter_available_to_user
    return unless user && filter

    unless filter.tenant_id == user.tenant_id && (filter.common? || filter.author_id == user.id)
      errors.add(:filter, "is not available to this user")
    end
  end
end
