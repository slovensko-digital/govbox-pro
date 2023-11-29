require "test_helper"

class Govbox::MessageTest < ActiveSupport::TestCase
  test "should create message, its objects and not visible tag" do
    govbox_message = govbox_messages(:one)

    Govbox::Message.create_message_with_thread!(govbox_message)

    message = Message.last

    assert_equal message.title, "MySubject"
    assert_equal message.sender_name, "MySender"
    assert_equal message.recipient_name, "MyRecipient"
    assert_equal message.html_visualization, "MyHtml"

    assert_equal message.objects.count, 1
    assert_equal message.objects.first.name, "MyName"
    assert_equal message.objects.first.mimetype, "MyMimeType"
    assert_equal message.objects.first.is_signed, true
    assert_equal message.objects.first.object_type, "MyClass"

    assert_equal message.objects.first.message_object_datum.blob, "MyContent"

    assert_equal message.tags.count, 1
    assert message.tags.first.is_a?(ExternalTag)
    assert_equal message.tags.first.name, "slovensko.sk:#{govbox_message.folder.name}"
    assert_equal message.tags.first.visible, false
    assert_equal message.thread.tags.count, 1
    assert_equal message.tags.first, message.thread.tags.first
  end

  test "should include general agenda subject in message title" do
    govbox_message = govbox_messages(:ssd_general_agenda)

    Govbox::Message.create_message_with_thread!(govbox_message)

    message = Message.last

    assert_equal message.title, "Všeobecná Agenda - Rozhodnutie ..."
  end

  test "should not create new tag if already exists" do
    govbox_message = govbox_messages(:one)

    tag = ExternalTag.create!(system_name: "slovensko.sk:#{govbox_message.folder.name}", name: "slovensko.sk:#{govbox_message.folder.name}", tenant: govbox_message.folder.box.tenant, visible: false)

    Govbox::Message.create_message_with_thread!(govbox_message)

    message = Message.last

    assert_equal message.tags.count, 1
    assert_equal message.tags.first, tag
    assert_equal message.thread.tags.count, 1
    assert_equal message.thread.tags.first, tag
  end

  test "should not duplicate message thread tags" do
    govbox_message1 = govbox_messages(:one)
    govbox_message2 = govbox_messages(:three)

    tag = ExternalTag.create!(system_name: "slovensko.sk:#{govbox_message1.folder.name}", name: "slovensko.sk:#{govbox_message1.folder.name}", tenant: govbox_message1.folder.box.tenant, visible: false)

    Govbox::Message.create_message_with_thread!(govbox_message1)
    message1 = Message.last

    Govbox::Message.create_message_with_thread!(govbox_message2)
    message2 = Message.last

    assert_equal message1.tags.count, 1
    assert_equal message1.tags.first, tag
    assert_equal message1.thread.tags.count, 1
    assert_equal message1.thread.tags.first, tag

    assert_equal message2.tags.count, 1
    assert_equal message2.tags.first, tag
    assert_equal message2.thread.tags.count, 1
    assert_equal message2.thread.tags.first, tag
  end

  test "should not use delivery notification title for message thread title" do
    govbox_message = govbox_messages(:solver_delivery_notification)

    Govbox::Message.create_message_with_thread!(govbox_message)
    message = Message.last
    message_thread = MessageThread.last

    assert_not_equal message.title, message_thread.title
    assert_equal message.metadata["delivery_notification"]["consignment"]["subject"], message_thread.title
  end
end
