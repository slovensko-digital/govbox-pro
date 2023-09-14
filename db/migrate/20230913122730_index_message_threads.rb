class IndexMessageThreads < ActiveRecord::Migration[7.0]
  def up
    Searchable::MessageThread.reset_column_information

    say_with_time("Indexing MessageThreads") do
      Searchable::MessageThread.reindex_all
    end
  end

  def down
  end
end
