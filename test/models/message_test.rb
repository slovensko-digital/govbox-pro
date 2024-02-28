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

  test "reply to message should create a valid draft" do
    message = messages(:ssd_main_general_one)
    user = users(:basic)

    reply = MessageDraft.new
    MessageTemplate.reply_template.create_message_reply(reply, original_message: message, author: user)

    assert_equal reply.sender_name, message.recipient_name
    assert_equal reply.recipient_name, message.sender_name
    assert_equal reply.message_thread_id, message.message_thread_id
    assert_match message.title, reply.title
    assert_match "Odpoveď", reply.title
    assert_equal reply.type, "MessageDraft"
    assert_equal reply.author_id, user.id
    assert_not reply.collapsed
  end
end
