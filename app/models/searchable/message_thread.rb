class Searchable::MessageThread < ApplicationRecord

  belongs_to :message_thread, class_name: '::MessageThread'
  belongs_to :tenant, class_name: '::Tenant'

  include PgSearch::Model
  pg_search_scope :pg_search_all,
                  against: [:title, :content, :tag_names]

  def self.fulltext_search(query)
    pg_search_all(
      Searchable::IndexHelpers.searchable_string(query)
    )
  end

  def self.search_ids(query_filter, tenant_id:, permitted_tag_ids:, cursor:, per_page:, direction: )
    scope = self

    scope = scope.where(tenant_id: tenant_id)

    if permitted_tag_ids.any?
      scope = scope.where("tag_ids && ARRAY[?]", permitted_tag_ids)
    else
      scope = scope.none
    end

    if query_filter[:filter_tag_ids].present?
      if query_filter[:filter_tag_ids] == :missing_tag
        scope = scope.none
      else
        scope = scope.where("tag_ids @> ARRAY[?]", query_filter[:filter_tag_ids])
      end
    end
    scope = scope.where.not("tag_ids && ARRAY[?]", query_filter[:filter_out_tag_ids]) if query_filter[:filter_out_tag_ids].present?
    scope = scope.fulltext_search(query_filter[:fulltext]) if query_filter[:fulltext].present?
    scope = scope.select(:message_thread_id, :last_message_delivered_at)

    # remove default order rule given by pg_search
    scope = scope.reorder("")

    collection, next_cursor = Pagination.paginate(
      collection: scope,
      cursor: cursor,
      items_per_page: per_page,
      direction: direction
    )

    ids = collection.map(&:message_thread_id)

    [ids, next_cursor]
  end

  def self.index_record(message_thread)
    record = ::Searchable::MessageThread.find_or_initialize_by(message_thread_id: message_thread.id)
    record.title = Searchable::IndexHelpers.searchable_string(message_thread.title)
    record.tag_ids = message_thread.tags.map(&:id)
    record.tag_names = Searchable::IndexHelpers.searchable_string(message_thread.tags.map(&:name).join(' ').gsub(/[:\/]/, " "))
    record.content = message_thread.messages.map do |message|
      [
        Searchable::IndexHelpers.searchable_string(message.title),
        Searchable::IndexHelpers.searchable_string(message.sender_name),
        Searchable::IndexHelpers.html_to_searchable_string(message.html_visualization)
      ].compact.join(' ')
    end.join(' ')

    record.last_message_delivered_at = message_thread.last_message_delivered_at
    record.tenant_id = message_thread.folder.box.tenant_id

    record.save!
  end

  def self.reindex_with_tag_id(tag_id)
    Searchable::MessageThread.select(:id, :message_thread_id).where("tag_ids && ARRAY[?]", [tag_id]).find_each do |searchable_mt|
      Searchable::ReindexMessageThreadJob.perform_later(::MessageThread.find(searchable_mt.message_thread_id))
    end
  end

  def self.reindex_all
    ::MessageThread.includes(:tags, :messages, folder: :box).find_each { |mt| index_record(mt) }
  end
end
