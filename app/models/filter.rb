# == Schema Information
#
# Table name: filters
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  position   :integer          not null
#  query      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  author_id  :bigint
#  tenant_id  :bigint           not null
#
class Filter < ApplicationRecord
  include AuditableEvents

  belongs_to :author, class_name: 'User', foreign_key: :author_id, optional: true
  belongs_to :tenant
  has_many :filter_subscriptions, dependent: :destroy

  validates :tenant_id, :author_id, :name, :query, presence: true

  before_create :fill_position

  def fill_position
    return if position.present?

    max_position = Filter.where(tenant_id: tenant_id).maximum(:position)

    self.position = (max_position || 0) + 1
  end
end
