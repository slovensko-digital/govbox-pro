require "test_helper"

class Govbox::MessageTest < ActiveSupport::TestCase
  test "#create_message_with_thread! should create message, its objects and not visible tag" do
    govbox_message = govbox_messages(:one)

    Govbox::Message.create_message_with_thread!(govbox_message)

    message = Message.last

    assert_equal message.title, "MySubject"
    assert_equal message.sender_name, "MySender"
    assert_equal message.recipient_name, "MyRecipient"
    assert_equal message.html_visualization, "general text"

    assert_equal message.objects.count, 1
    assert_equal message.objects.first.name, "MyName"
    assert_equal message.objects.first.mimetype, "MyMimeType"
    assert_equal message.objects.first.is_signed, true
    assert_equal message.objects.first.object_type, "MyClass"

    assert_equal message.objects.first.message_object_datum.blob, "MyContent"

    assert_equal 1, message.tags.count
    assert_equal "slovensko.sk:#{govbox_message.folder.name}", message.tags.first.name
    assert_equal "slovensko.sk:#{govbox_message.folder.name}", message.tags.first.external_name
    assert_not message.tags.first.visible
    assert_equal 1, message.thread.tags.simple.count
    assert_equal message.tags.first, message.thread.tags.simple.first
  end

  test "#create_message_with_thread! migrates tags from associated MessageDraft" do
    govbox_message = govbox_messages(:ssd_general_created_from_draft)

    Govbox::Message.create_message_with_thread!(govbox_message)

    message = Message.last

    # Simple and Signed tags copied to MessageThread
    assert ['Finance', 'Podpísané', 'Podpísané: Signer user'].map { |tag_name| message.thread.tags.include?(tag_name) }

    # No SignatureRequested, Submiited tags copied to MessageThread
    assert message.thread.tags.where(type: ['SignatureRequestedTag', 'SignatureRequestedFromTag', 'Submitted']).none?

    # Signed tags copied to MessageObjects
    assert message.objects.find_by(name: 'Attachment2').tags.include?(tags(:ssd_signer_user_signed))

    # No SignatureRequested tags copied to MessageObjects
    assert message.form_object.tags.where(type: ['SignatureRequestedTag', 'SignatureRequestedFromTag']).none?
  end

  test "#create_message_with_thread! should take name from box as recipient_name if no recipient_name in govbox message" do
    govbox_message = govbox_messages(:ssd_without_recipient_name)

    Govbox::Message.create_message_with_thread!(govbox_message)

    message = Message.last

    assert_equal message.title, "Všeobecná Agenda - Rozhodnutie ..."
    assert_equal message.sender_name, "MySender"
    assert_equal message.recipient_name, "SSD main"
  end

  test "#create_message_with_thread! should handle adding inbox tag to thread" do
    Govbox::Message.create_message_with_thread!(govbox_messages(:ssd_egov_application))

    message_thread = MessageThread.last

    # Inbox tag not added when outbox message processed
    assert_not message_thread.tags.include?(tags(:ssd_inbox))

    Govbox::Message.create_message_with_thread!(govbox_messages(:ssd_posting_confirmation))
    # Inbox tag not added when insignificant inbox message processed
    assert_not message_thread.tags.include?(tags(:ssd_inbox))

    Govbox::Message.create_message_with_thread!(govbox_messages(:ssd_delivery_report))
    # Inbox tag not added when another insignificant inbox message processed
    assert_not message_thread.tags.include?(tags(:ssd_inbox))

    # Outbox or insignificant messages are automatically marked read
    assert message_thread.messages.reload.all?{|m| m.read?}

    Govbox::Message.create_message_with_thread!(govbox_messages(:ssd_egov_document))
    # Inbox tag is added when significant inbox message processed
    assert message_thread.tags.include?(tags(:ssd_inbox))

    # Significant inbox messages is marked unread
    assert_not message_thread.messages.reload.all?{|m| m.read?}
    assert_not message_thread.messages.last.read?
  end

  test "#create_message_with_thread! should include general agenda subject in message title" do
    govbox_message = govbox_messages(:ssd_general_agenda)

    Govbox::Message.create_message_with_thread!(govbox_message)

    message = Message.last

    assert_equal message.title, "Všeobecná Agenda - Rozhodnutie ..."
  end

  test "#create_message_with_thread! should not create new tag if already exists" do
    govbox_message = govbox_messages(:one)

    tag = SimpleTag.create!(external_name: "slovensko.sk:#{govbox_message.folder.name}", name: "slovensko.sk:#{govbox_message.folder.name}", tenant: govbox_message.folder.box.tenant, visible: false)

    Govbox::Message.create_message_with_thread!(govbox_message)

    message = Message.last

    assert_equal 1, message.tags.count
    assert_equal tag, message.tags.first
    assert_equal 1, message.thread.tags.simple.count
    assert_equal tag, message.thread.tags.simple.first
  end

  test "#create_message_with_thread! should not duplicate message thread tags" do
    govbox_message1 = govbox_messages(:one)
    govbox_message2 = govbox_messages(:three)

    tag = SimpleTag.create!(external_name: "slovensko.sk:#{govbox_message1.folder.name}", name: "slovensko.sk:#{govbox_message1.folder.name}", tenant: govbox_message1.folder.box.tenant, visible: false)

    Govbox::Message.create_message_with_thread!(govbox_message1)
    message1 = Message.last

    Govbox::Message.create_message_with_thread!(govbox_message2)
    message2 = Message.last

    assert_equal tag, message1.tags.first
    assert_equal 1, message1.thread.tags.simple.count
    assert_equal tag, message1.thread.tags.simple.first

    assert_equal 1, message2.tags.simple.count
    assert_equal tag, message2.tags.simple.first
    assert_equal 1, message2.thread.tags.simple.count
    assert_equal tag, message2.thread.tags.simple.first
  end

  test "#create_message_with_thread! should not use delivery notification title for message thread title" do
    govbox_message = govbox_messages(:solver_delivery_notification)

    Govbox::Message.create_message_with_thread!(govbox_message)
    message = Message.last
    message_thread = MessageThread.last

    assert_not_equal message.title, message_thread.title
    assert_equal message.metadata["delivery_notification"]["consignment"]["subject"], message_thread.title
  end
end
