require "test_helper"

class MessageTest < ActiveSupport::TestCase
  test "add_cascade_tag method should add tag to message and message thread" do
    message = messages(:ssd_main_general_one)
    tag = tags(:ssd_finance)

    message.add_cascading_tag(tag)

    assert message.tags.include?(tag)
    assert message.thread.tags.include?(tag)
  end

  test "remove_cascade_tag method should delete tag from message and also message thread if no more messages with the tag" do
    message = messages(:solver_main_delivery_notification_one)
    tag = tags(:solver_delivery_notification)

    message.remove_cascading_tag(tag)

    assert_equal message.tags.include?(tag), false
    assert_equal message.thread.tags.include?(tag), false
  end

  test "remove_cascade_tag method should delete tag from message and keep it on message thread if more messages with the tag" do
    message = messages(:ssd_main_general_one)
    tag = tags(:ssd_external)

    message.remove_cascading_tag(tag)

    assert_equal message.tags.include?(tag), false
    assert message.thread.tags.include?(tag)
  end
end
