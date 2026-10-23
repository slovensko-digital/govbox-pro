require "test_helper"

class MessageThreadsTableRowTest < ActionView::TestCase
  test "search highlight keeps highlight spans but strips markup injected into indexed fields" do
    message_thread = MessageThread.select("message_threads.*", "true AS all_read", "NULL AS sender", "NULL AS recipient").find(message_threads(:ssd_main_general).id)
    message_thread.search_highlight = %(<span class="bg-yellow-200 text-gray-950">searchx15</span> <img src=x onerror="alert('XSS')">)

    render partial: "shared/message_threads_table_row", collection: [message_thread], as: :message_thread

    assert_select "span.bg-yellow-200", text: "searchx15"
    assert_select "img", count: 0
    assert_not_includes rendered, "onerror"
  end
end
