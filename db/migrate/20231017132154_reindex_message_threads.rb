class ReindexMessageThreads < ActiveRecord::Migration[7.0]
  def up
    say_with_time("Reindexing MessageThreads") do
      Searchable::MessageThread.reindex_all
    end
  end

  def down
  end
end
