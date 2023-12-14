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

  validates_presence_of :events, on: :create

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
    raise SecurityError unless tag_ids.any?

    scope = searchable
              .where(tenant_id: tenant)
              .where("tag_ids && ARRAY[?]", tag_ids)

    query = Searchable::MessageThreadQuery.labels_to_ids(
      Searchable::MessageThreadQuery.parse(filter.query),
      tenant: tenant
    )

    if query[:filter_tag_ids].present?
      return none if query[:filter_tag_ids] == :missing_tag

      scope = scope.where("tag_ids @> ARRAY[?]", query[:filter_tag_ids])
    end

    scope = scope.where.not("tag_ids && ARRAY[?]", query[:filter_out_tag_ids]) if query[:filter_out_tag_ids].present?
    scope = scope.fulltext_search(query[:fulltext]) if query[:fulltext].present?

    scope
  end
end
