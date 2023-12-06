require "test_helper"

class EverythingTagTest < ActiveSupport::TestCase
  test "adds everything tag to every thread" do
    box = boxes(:ssd_main)
    thread = box.message_threads.create!(
      title: 'Test',
      original_title: 'Test',
      delivered_at: Time.current,
      last_message_delivered_at: Time.current
    )

    assert_includes thread.tags, box.tenant.everything_tag
  end
end
