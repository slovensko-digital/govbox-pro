class Searchable::MessageThread < ApplicationRecord
  belongs_to :message_thread, class_name: '::MessageThread'
  belongs_to :tenant, class_name: '::Tenant'

  include PgSearch::Model
  pg_search_scope :pg_search_all,
                  against: [:title, :content, :tag_names],
                  using: {
                    tsearch: {
                      highlight: {
                        StartSel: '<b>',
                        StopSel: '</b>',
                        MaxWords: 15,
                        MinWords: 0,
                        ShortWord: 1,
                        HighlightAll: true,
                        MaxFragments: 1,
                        FragmentDelimiter: '&hellip;'
                      }
                    }
                  }

  def self.fulltext_search(query)
    pg_search_all(
      Searchable::IndexHelpers.searchable_string(query)
    )
  end

  def self.search_ids(query_filter, search_permissions:, cursor:, per_page:, direction: )
    scope = self

    scope = scope.where(tenant_id: search_permissions.fetch(:tenant_id))
    scope = scope.where(box_id: search_permissions.fetch(:box_id)) if search_permissions[:box_id]

    if search_permissions.key?(:tag_ids)
      if search_permissions[:tag_ids].any?
        scope = scope.where("tag_ids && ARRAY[?]", search_permissions[:tag_ids])
      else
        scope = scope.none
      end
    end

    if query_filter[:filter_tag_ids].present?
      if query_filter[:filter_tag_ids] == :missing_tag
        scope = scope.none
      else
        scope = scope.where("tag_ids @> ARRAY[?]", query_filter[:filter_tag_ids])
      end
    end
    scope = scope.where.not("tag_ids && ARRAY[?]", query_filter[:filter_out_tag_ids]) if query_filter[:filter_out_tag_ids].present?
    scope = scope.fulltext_search(query_filter[:fulltext]).with_pg_search_highlight if query_filter[:fulltext].present?
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

    if query_filter[:fulltext].present?
      highlights = collection.each_with_object({}) { |record, map| map[record.message_thread_id] = record.pg_search_highlight }

      {
        ids: ids,
        next_cursor: next_cursor,
        highlights: highlights,
      }
    else
      {
        ids: ids,
        next_cursor: next_cursor,
        highlights: {},
      }
    end
  end

  def self.reindex_with_tag_id(tag_id)
    Searchable::MessageThread.select(:id, :message_thread_id).where("tag_ids && ARRAY[?]", [tag_id]).find_each do |searchable_mt|
      Searchable::ReindexMessageThreadJob.perform_later(::MessageThread.find(searchable_mt.message_thread_id))
    end
  end

  def self.reindex_all
    ::MessageThread.includes(:tags, :messages, folder: :box).find_each { |mt| ::Searchable::Indexer.index_message_thread(mt) }
  end
end
