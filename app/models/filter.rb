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
  belongs_to :tag, optional: true
  has_many :filter_subscriptions, dependent: :destroy
  has_many :user_filter_visibilities, dependent: :destroy

  scope :common, -> { where(common: true) }
  scope :personal, -> { where(common: false) }

  def self.available_to(user)
    tenant_filters = where(tenant_id: user.tenant_id)
    available = tenant_filters.common.or(tenant_filters.personal.where(author_id: user.id))
    private_tags = user.tenant.tags.where.not(owner_id: [nil, user.id])
    group_signer_tags = user.tenant.tags.where(type: ["SignatureRequestedFromTag", "SignedByTag"], owner_id: nil)
    available.where.not(tag_id: private_tags.select(:id)).where.not(tag_id: group_signer_tags.select(:id))
      .or(available.where(tag_id: nil))
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

  def query_change_confirmation(attributes)
    confirmation_verifier.generate(query_change_payload(attributes), purpose: "query-change", expires_in: 15.minutes)
  end

  def update_with_confirmation(attributes, token: nil)
    with_lock do
      normalized = normalized_changes(attributes)
      requires_confirmation = common? && normalized.key?("query") && normalized["query"] != query
      confirmed = confirmation_verifier.verified(token, purpose: "query-change") == query_change_payload(normalized) if token.present?
      if requires_confirmation && !confirmed
        :confirmation_required
      else
        update(normalized) ? :updated : :invalid
      end
    end
  end

  def deletion_confirmation
    confirmation_verifier.generate(deletion_payload, purpose: "delete-filter", expires_in: 15.minutes)
  end

  def destroy_with_confirmation(token: nil)
    with_lock do
      confirmed = confirmation_verifier.verified(token, purpose: "delete-filter") == deletion_payload if token.present?
      if common? && filter_subscriptions.exists? && !confirmed
        :confirmation_required
      else
        destroy!
        :destroyed
      end
    end
  end

  def fill_position
    return if position.present?

    max_position = Filter.where(tenant_id: tenant_id).maximum(:position)

    self.position = (max_position || 0) + 1
  end

  private

  def confirmation_verifier
    Rails.application.message_verifier("common-filter-confirmations")
  end

  def normalized_changes(attributes)
    attributes.to_h.stringify_keys.slice("name", "query").tap do |changes|
      changes["query"] = changes["query"].to_s.strip if changes.key?("query")
    end
  end

  def query_change_payload(attributes)
    { "id" => id, "tenant_id" => tenant_id, "query" => query,
      "updated_at" => updated_at.iso8601(6), "changes" => normalized_changes(attributes) }
  end

  def deletion_payload
    { "id" => id, "tenant_id" => tenant_id, "updated_at" => updated_at.iso8601(6),
      "subscriptions" => filter_subscriptions.order(:id).pluck(:id, :user_id) }
  end

  def initialize_preferences
    common? ? distribute! : author.set_filter_visibility!(id, visible: false)
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
