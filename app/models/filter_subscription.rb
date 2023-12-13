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
  AVAILABLE_EVENT_NAMES = [:message_thread_changed, :message_created, :message_thread_note_changed].freeze

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

  def create_notifications!
    run_started_at = Time.current
    events.each do |event|
      case event.to_sym
      when :message_thread_changed
        new_threads.each do |searchable|
          user.notifications.create!(
            type: Notifications::MessageThreadChanged, # TODO better name changed?
            message_thread_id: searchable.message_thread_id,
            filter_subscription: self,
            filter_name: filter.name,
          )
        end
      when :message_created
        threads_with_new_messages.each do |searchable|
          searchable.new_message_ids.each do |message_id|
            user.notifications.create!(
              type: Notifications::MessageCreated,
              message_thread_id: searchable.message_thread_id,
              message_id: message_id,
              filter_subscription: self,
              filter_name: filter.name
            )
          end
        end
      when :message_thread_note_changed
        threads_with_changed_note.each do |searchable|
          user.notifications.create!(
            type: Notifications::MessageThreadNoteChanged,
            message_thread_id: searchable.message_thread_id,
            filter_subscription: self,
            filter_name: filter.name
          )
        end
      else
        raise NotImplementedError
      end
    end

    self.last_notify_run_at = run_started_at
    save!
  end

  def new_threads
    notification_already_exists = Notifications::MessageThreadChanged
                                    .select(1)
                                    .where("searchable_message_threads.message_thread_id = message_thread_id")
                                    .where("created_at >= ?", created_at)
                                    .limit(1)
                                    .arel.exists

    Searchable::MessageThread
      .matching(self)
      .where("message_thread_updated_at > ?", last_notify_run_at)
      .where.not(notification_already_exists)
  end

  def threads_with_new_messages
    new_message_ids = Message
                        .select("ARRAY_AGG(id)")
                        .where("searchable_message_threads.message_thread_id = message_thread_id")
                        .where("created_at >= ?", last_notify_run_at)

    Searchable::MessageThread
      .matching(self)
      .select("searchable_message_threads.*, (#{new_message_ids.to_sql}) AS new_message_ids")
      .where("last_message_created_at > ?", last_notify_run_at)
  end

  def threads_with_changed_note
    Searchable::MessageThread
      .matching(self)
      .where("message_thread_note_updated_at > ?", last_notify_run_at)
  end
end
