class ReindexSearchableWithHtmlBody < ActiveRecord::Migration[7.1]
  def change
    Searchable::MessageThread.reindex_all
  end
end
