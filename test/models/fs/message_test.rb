# frozen_string_literal: true

require "test_helper"
require "active_support/all"

class Fs::MessageTest < ActiveSupport::TestCase
  test "#create_inbox_message creates new message with delivered_at and fs_submission_created_at values in same format" do
    raw_message = {
      "created_at" => "2024-06-05T10:27:03.105Z",
      "message_id" => "12345689/2024",
      "submission_type_id" => "3079",
      "submission_type_name" => "Podanie pre FS  (Správa daní) – späťvzatie žiadosti",
      "message_type_id" => "DRSR_POPP_v02",
      "message_type_name" => "Informácia o podaní",
      "sent_message_id" => "12345689/2024",
      "seen" => true,
      "is_ekr2" => true,
      "status" => "Vybavená",
      "submission_status" => "Prijaté a potvrdené",
      "dic" => "1122222333",
      "subject" => "xy",
      "submitting_subject" => "xy",
      "submission_created_at" => "2024-06-05T10:27:01.433Z",
      "period" => nil,
      "dismissal_reason" => nil,
      "message_container" =>
        {
          "message_id" => SecureRandom.uuid,
          "sender_id" => "FSSR",
          "recipient_id" => "1122222333",
          "message_type" => "ED.DeliveryReport",
          "subject" => "x",
          "objects" => [
            {
              "class" => "FORM",
              "description" => "DeliveryReport",
              "encoding" => "Base64",
              "id" => SecureRandom.uuid,
              "signed" => true,
              "mime_type" => "application/vnd.etsi.asic-e+zip",
              "name" => "DeliveryReport",
              "content" =>
                "content xy"
            }
          ]
        }
    }

    message = Fs::Message.create_inbox_message(raw_message)

    assert_equal '2024-06-05 12:27:03 +0200', message.delivered_at.to_s
    assert_equal '2024-06-05T12:27:01.433+02:00', message.metadata['fs_submission_created_at']
  end

  test "#create_inbox_message_with_thread handles adding inbox tag to thread" do
    raw_message = {
      "created_at" => "2024-06-05T10:27:03.105Z",
      "message_id" => "12345689/2024",
      "submission_type_id" => "3079",
      "submission_type_name" => "Podanie pre FS  (Správa daní) – späťvzatie žiadosti",
      "message_type_id" => "DRSR_POPP_v02",
      "message_type_name" => "Informácia o podaní",
      "sent_message_id" => "1234/2024",
      "seen" => true,
      "is_ekr2" => true,
      "status" => "Vybavená",
      "submission_status" => "Prijaté a potvrdené",
      "dic" => "1122222333",
      "subject" => "xy",
      "submitting_subject" => "xy",
      "submission_created_at" => "2024-06-05T10:27:01.433Z",
      "period" => nil,
      "dismissal_reason" => nil,
      "message_container" =>
        {
          "message_id" => SecureRandom.uuid,
          "sender_id" => "FSSR",
          "recipient_id" => "1122222333",
          "message_type" => "ED.DeliveryReport",
          "subject" => "x",
          "objects" => [
            {
              "class" => "FORM",
              "description" => "DeliveryReport",
              "encoding" => "XML",
              "id" => SecureRandom.uuid,
              "signed" => true,
              "mime_type" => "application/xml",
              "name" => "DeliveryReport",
              "content" =>
                "<content>xy</content>"
            }
          ]
        }
    }

    Fs::Message.create_inbox_message_with_thread!(raw_message, box: boxes(:fs_accountants))

    assert Message.last.thread.tags.include?(tags(:accountants_inbox))
  end

  test "#create_outbox_message_with_thread assigns author and author tag from associated message draft" do
    draft = messages(:fs_accountants_draft)

    raw_message = {
      "created_at" => Time.now.to_s,
      "message_container" => { "message_id" => SecureRandom.uuid, "objects" => [] },
      "submission_type_name" => "FS Podanie",
      "subject" => "FS Subject",
      "message_id" => draft.metadata['fs_message_id'],
      "status" => "Odoslané",
      "submitting_subject" => "Firma s.r.o.",
      "dismissal_reason" => nil,
      "other_attributes" => {},
      "dic" => "2020202020"
    }

    message = Fs::Message.create_outbox_message_with_thread!(raw_message, box: draft.box)

    assert_equal draft.author, message.author, "Author should be assigned to the outbox message"
    assert message.tags.include?(draft.author.author_tag), "Author tag should be assigned to the outbox message"
    assert message.thread.tags.include?(draft.author.author_tag), "Author tag should be assigned to the message thread"
  end
end
