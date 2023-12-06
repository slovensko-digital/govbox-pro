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
    message = messages(:ssd_main_general_one)
    tag = tags(:ssd_finance)

    message.add_cascading_tag(tag)

    assert message.tags.include?(tag)
    assert message.thread.tags.include?(tag)

    message.remove_cascading_tag(tag)

    assert_not message.tags.include?(tag)
    assert_not message.thread.tags.include?(tag)
  end

  test "remove_cascade_tag method should delete tag from message and keep it on message thread if more messages with the tag" do
    message = messages(:ssd_main_general_one)
    tag = tags(:ssd_external)

    message.remove_cascading_tag(tag)

    assert_not message.tags.include?(tag)
    assert message.thread.tags.include?(tag)
  end

  test "adds everything tag to every message" do

  end
end
