# == Schema Information
#
# Table name: filter_subscriptions
#
#  id                 :bigint           not null, primary key
#  events             :string           default([]), not null, is an Array
#  last_notify_run_at :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  filter_id          :bigint           not null
#  tenant_id          :bigint           not null
#  user_id            :bigint           not null
#
class FilterSubscription < ApplicationRecord
  EVENT_TYPES = [
    Notifications::NewMessageThread,
    Notifications::NewMessage,
    Notifications::MessageThreadNoteChanged
  ].freeze

  AVAILABLE_EVENT_NAMES = EVENT_TYPES.map(&:to_s).freeze

  EVENT_TYPES_MAP = EVENT_TYPES.index_by(&:to_s)

  belongs_to :tenant
  belongs_to :user
  belongs_to :filter

  def self.for_query(user, query)
    where(user_id: user.id, tenant_id: user.tenant_id,
      filter_id: Filter.available_to(user).where(query: query.to_s.strip).select(:id))
  end

  validates_presence_of :events, on: :create
  validate :consistent_ownership

  before_create { self.last_notify_run_at = Time.current }

  def update_or_destroy(params)
    if params[:events].present?
      update(params)
      true
    else
      destroy
      false
    end
  end

  def event_types
    events.map { |e| EVENT_TYPES_MAP[e.to_s] }
  end

  # TODO move to concerns?
  def scope_searchable(searchable)
    # TODO scope searchable on user / query?
    # searchable
    #       .matching(user)
    #       .matching(query)

    tag_ids = user.accessible_tags.pluck(:id)
    return searchable.none unless tag_ids.any?

    scope = searchable
              .where(tenant_id: tenant)
              .where(box_id: user.accessible_boxes.select(:id))
              .where("tag_ids && ARRAY[?]::integer[]", tag_ids)

    query = Searchable::MessageThreadQuery.labels_to_ids(
      Searchable::MessageThreadQuery.parse(filter.query, user_tag_name: user.author_tag&.name),
      tenant: tenant
    )

    if query[:filter_tag_ids].present?
      return scope.none if query[:filter_tag_ids] == :missing_tag

      scope = scope.where("tag_ids @> ARRAY[?]::integer[]", query[:filter_tag_ids])
    end

    scope = scope.where.not("tag_ids && ARRAY[?]::integer[]", query[:filter_out_tag_ids]) if query[:filter_out_tag_ids].present?
    scope = scope.fulltext_search(query[:fulltext], prefix_search: query[:prefix_search]) if query[:fulltext].present?

    scope
  end

  private

  def consistent_ownership
    return unless user && filter

    if tenant_id != user.tenant_id || filter.tenant_id != user.tenant_id || (!filter.common? && filter.author_id != user.id)
      errors.add(:filter, "is not available to this user")
    end
    errors.add(:events, "contains an unknown notification event") if (Array(events) - AVAILABLE_EVENT_NAMES).any?
  end
end
