require "test_helper"

class Searchable::MessageThreadTest < ActiveSupport::TestCase
  test "tag overlap accepts both integer and string IDs" do
    thread = message_threads(:ssd_main_general)
    Searchable::Indexer.index_message_thread(thread)
    tag = thread.tags.first

    assert_includes Searchable::MessageThread.with_tag_id(tag.id).pluck(:message_thread_id), thread.id
    assert_includes Searchable::MessageThread.with_tag_id(tag.id.to_s).pluck(:message_thread_id), thread.id
  end
end
