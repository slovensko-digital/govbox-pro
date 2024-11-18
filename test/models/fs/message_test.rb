# frozen_string_literal: true

require "test_helper"
require "active_support/all"

class Fs::MessageTest < ActiveSupport::TestCase
  test "#create_inbox_messages save datetime attributes with the needed timezone" do
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
end
