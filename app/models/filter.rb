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
#  author_id  :bigint           not null
#  tenant_id  :bigint           not null
#
class Filter < ApplicationRecord
  include AuditableEvents

  belongs_to :author, class_name: 'User', foreign_key: :author_id, optional: true
  belongs_to :tenant
  has_many :filter_subscriptions, dependent: :destroy
  has_many :user_filter_visibilities, dependent: :destroy

  scope :common, -> { where(common: true) }
  scope :personal, -> { where(common: false) }

  def self.available_to(user)
    tenant_filters = where(tenant_id: user.tenant_id)
    tenant_filters.common.or(tenant_filters.personal.where(author_id: user.id))
  end

  def self.effective_for(user)
    available_to(user).where(<<~SQL, user.id)
      NOT filters.common OR NOT EXISTS (
        SELECT 1 FROM filters personal_filters
        WHERE personal_filters.tenant_id = filters.tenant_id
          AND personal_filters.author_id = ?
          AND NOT personal_filters.common
          AND personal_filters.query = filters.query
      )
    SQL
  end

  def self.for_query(user, query)
    effective_for(user).find_by(query: query.to_s.strip)
  end

  validates :tenant_id, :name, presence: true
  validates :author_id, presence: true, unless: :common?
  validates :query, exclusion: { in: [nil] }
  validates :common, inclusion: { in: [true, false] }
  validates :query, uniqueness: { scope: :tenant_id, conditions: -> { where(common: true) } }, if: :common?
  validates :query, uniqueness: { scope: [:tenant_id, :author_id], conditions: -> { where(common: false) } }, unless: :common?
  validate :author_belongs_to_tenant

  before_validation :trim_query

  around_create :serialize_position
  before_create :fill_position
  after_create_commit :initialize_preferences

  def distribute!
    raise ArgumentError, "Only common filters can be distributed" unless common?

    tenant.users.find_each(batch_size: 100) { |user| user.add_common_filter!(self) }
  end

  def fill_position
    return if position.present?

    max_position = Filter.where(tenant_id: tenant_id).maximum(:position)

    self.position = (max_position || 0) + 1
  end

  private

  def initialize_preferences
    common? ? distribute! : author.set_filter_visibility!(id, visible: true)
  end

  def serialize_position(&block)
    tenant.with_lock(&block)
  end

  def trim_query
    self.query = query.strip unless query.nil?
  end

  def author_belongs_to_tenant
    errors.add(:author, "must belong to the same tenant") if author && author.tenant_id != tenant_id
  end
end
