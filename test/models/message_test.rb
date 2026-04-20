require "test_helper"

class MessageTest < ActiveSupport::TestCase
  test "Automatically sets html_visualization after form object data created" do
    message = messages(:ssd_main_general_four)

    form = message.objects.create(
      name: 'form',
      mimetype: 'application/xml',
      object_type: 'FORM'
    )
    MessageObjectDatum.create(
      message_object: form,
      blob: '<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><subject>predmet</subject><text>text</text></GeneralAgenda>'
    )

    assert message.html_visualization.present?
  end

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

    reply = MessageTemplate.reply_template.create_message_reply(original_message: message, author: user)

    assert_equal reply.sender_name, message.recipient_name
    assert_equal reply.recipient_name, message.sender_name
    assert_equal reply.message_thread_id, message.message_thread_id
    assert_match message.title, reply.title
    assert_match "Odpoveď", reply.title
    assert_equal reply.type, "Upvs::MessageDraft"
    assert_equal reply.author_id, user.id
    assert_not reply.collapsed
  end

  test "#export_summary returns correct summary data" do
    message = messages(:fs_accountants_dphv21)

    expected_summary = {
      message_thread_id: message.message_thread_id,
      title: "FS podanie",
      box: "Accountants main FS",
      delivered_at: message.delivered_at,
      tags: [],
      outbox: true,
      dph_r33: "16002.44",
      dph_r35: "",
      fs_message_id: "12345678/2025",
      fs_status: "Prijaté a potvrdené",
      fs_submitting_subject: "GO FS subjekt",
      fs_period: "Q22025",
      correlation_id: "0d71fc24-05d3-4938-80e4-05bdc3be19fa"
    }

    assert_equal expected_summary, message.export_summary
  end
end
