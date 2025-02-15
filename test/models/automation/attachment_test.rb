require 'test_helper'

class Automation::AttachmentTest < ActiveSupport::TestCase
  test 'should run an automation on message created AttachmentContentContainsCondition ChangeMessageThreadTitleAction and not match' do
    govbox_message = govbox_messages(:ssd_general_agenda_with_lorem_pdf)
    govbox_message.payload["objects"].first["content"] = File.read("test/fixtures/files/lorem_ipsum.pdf")
    Govbox::Message.create_message_with_thread!(govbox_message)

    travel_to(15.minutes.from_now) { GoodJob.perform_inline }

    message = Message.last
    message.reload

    assert_not_includes message.thread.tags, tags(:ssd_attachment_matched)
    assert_equal "MySubject", message.thread.title
  end

  test 'should run an automation on message created AttachmentContentContainsCondition ChangeMessageThreadTitleAction and match simple string' do
    govbox_message = govbox_messages(:ssd_general_agenda_with_lorem_pdf)
    govbox_message.payload["objects"].first["content"] = File.read("test/fixtures/files/test_string.pdf")
    Govbox::Message.create_message_with_thread!(govbox_message)

    travel_to(15.minutes.from_now) { GoodJob.perform_inline }

    message = Message.last
    message.reload

    assert_includes message.thread.tags, tags(:ssd_attachment_matched)
    assert_equal "New title - MySubject", message.thread.title
  end

  test 'should run an automation on message created AttachmentContentContainsCondition ChangeMessageThreadTitleAction and match even in signed attachment' do
    govbox_message = govbox_messages(:ssd_general_agenda_with_lorem_pdf)
    govbox_message.payload["objects"].first["signed"] = true
    govbox_message.payload["objects"].first["mime_type"] = 'application/vnd.etsi.asic-e+zip'
    govbox_message.payload["objects"].first["content"] = File.read("test/fixtures/files/test_string_signed.asice")
    Govbox::Message.create_message_with_thread!(govbox_message)

    travel_to(15.minutes.from_now) { GoodJob.perform_inline }

    message = Message.last
    message.reload

    assert_includes message.thread.tags, tags(:ssd_attachment_matched)
    assert_equal "New title - MySubject", message.thread.title
  end

  test 'should run an automation on message created AttachmentContentContainsCondition ChangeMessageThreadTitleAction and match multiline string' do
    govbox_message = govbox_messages(:ssd_general_agenda_with_lorem_pdf)
    govbox_message.payload["objects"].first["content"] = File.read("test/fixtures/files/multiline_test.pdf")
    Govbox::Message.create_message_with_thread!(govbox_message)

    travel_to(15.minutes.from_now) { GoodJob.perform_inline }

    message = Message.last
    message.reload

    assert_includes message.thread.tags, tags(:ssd_attachment_matched)
    assert_equal "New title - MySubject", message.thread.title
  end

  test 'should run an automation on message created AttachmentContentContainsCondition ChangeMessageThreadTitleAction and match multipage string' do
    govbox_message = govbox_messages(:ssd_general_agenda_with_lorem_pdf)
    govbox_message.payload["objects"].first["content"] = File.read("test/fixtures/files/multipage_test.pdf")
    Govbox::Message.create_message_with_thread!(govbox_message)

    travel_to(15.minutes.from_now) { GoodJob.perform_inline }

    message = Message.last
    message.reload

    assert_includes message.thread.tags, tags(:ssd_attachment_matched)
    assert_equal "New title - MySubject", message.thread.title
  end
end
