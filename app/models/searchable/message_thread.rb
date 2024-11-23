# == Schema Information
#
# Table name: searchable_message_threads
#
#  id                        :bigint           not null, primary key
#  content                   :text             not null
#  last_message_delivered_at :datetime         not null
#  note                      :string           not null
#  tag_ids                   :integer          default([]), not null, is an Array
#  tag_names                 :text             not null
#  title                     :text             not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  box_id                    :integer          not null
#  message_thread_id         :integer          not null
#  tenant_id                 :integer          not null
#
class Searchable::MessageThread < ApplicationRecord
  belongs_to :message_thread, class_name: '::MessageThread'
  belongs_to :tenant, class_name: '::Tenant'

  scope :with_tag_id, ->(tag_id) { where("tag_ids && ARRAY[?]", [tag_id]) }

  include PgSearch::Model


  pg_search_scope :pg_search_all, lambda { |query, is_prefix = false|
    {
      query: query,
      against: [:title, :content, :note, :tag_names],
      using: {
        tsearch: {
          prefix: is_prefix,
          highlight: {
            StartSel: '<span class="bg-yellow-200 text-gray-950">', # if you change classed aad them to view in comment
            StopSel: '</span>',
            MaxWords: 15,
            MinWords: 0,
            ShortWord: 1,
            HighlightAll: true,
            MaxFragments: 2,
            FragmentDelimiter: '&hellip;'
          }
        }
      }
    }
  }

  def self.matching(scopeable)
    scopeable.scope_searchable(self) # double dispatch
  end


  def self.fulltext_search(query, prefix_search: false)
    pg_search_all(
      Searchable::IndexHelpers.searchable_string(query),
      prefix_search
    )
  end

  def self.search_ids(query_filter, search_permissions:, cursor:, per_page:, direction:)
    raise SecurityError if search_permissions[:tag_ids].present? && search_permissions[:tag_ids].empty?

    scope = self

    scope = scope.where(tenant_id: search_permissions.fetch(:tenant))
    scope = scope.where(box_id: search_permissions.fetch(:box)) if search_permissions[:box]

    if search_permissions[:tag_ids]
      if search_permissions[:tag_ids].any?
        scope = scope.where("tag_ids && ARRAY[?]", search_permissions[:tag_ids])
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
    scope = scope.fulltext_search(query_filter[:fulltext], prefix_search: query_filter[:prefix_search]).with_pg_search_highlight if query_filter[:fulltext].present?
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
      Searchable::ReindexMessageThreadJob.perform_later(searchable_mt.message_thread_id)
    end
  end

  def self.reindex_all
    ::MessageThread.includes(:tags, :messages, :message_thread_note, :box).find_each { |mt| ::Searchable::Indexer.index_message_thread(mt) }
  end
end
