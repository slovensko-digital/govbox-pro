class Searchable::ReindexMessageThreadsWithTagIdJob < ApplicationJob
  def perform(tag_id)
    ::Searchable::MessageThread.reindex_with_tag_id(tag_id)
  end
end
