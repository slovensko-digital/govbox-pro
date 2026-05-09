require "test_helper"

class Fs::DownloadSentMessageJobTest < ActiveJob::TestCase
  test "fetches sent message with API connection selected according to message draft" do
    message_draft = messages(:fs_accountants_multiple_api_connections_outbox)
    outbox_message = messages(:fs_accountants_outbox)

    fs_api = Minitest::Mock.new

    fs_client = Minitest::Mock.new
    fs_client.expect :api, fs_api, **{ api_connection: api_connections(:fs_api_connection5), box: message_draft.box }

    fs_api.expect :obo_without_delegate, "obo_without_delegate"
    fs_api.expect :fetch_sent_message, {
      "created_at" => "2025-10-21T10:33:12.516Z",
      "message_id" => "1235/2025",
      "submission_type_id" => "123",
      "submission_type_name" => "Daňové priznanie k dani z pridanej hodnoty (platné od 1.7.2025) - riadne",
      "status" => "Prijaté a potvrdené",
      "dic" => "9988665533",
      "subject" => "XY s. r. o.",
      "subject_name" => nil,
      "submitting_subject" => "XYZ 123",
      "is_ekr2" => true,
      "period" => "092025",
      "message_container" => {
        "message_id" => "061cb78a-3d6f-4921-861d-7a0a797c1cc8",
        "sender_id" => "123",
        "recipient_id" => "FSSR",
        "message_type" => "812",
        "subject" => "eDANEjava",
        "objects" => [
          {
            "class" => "FORM",
            "description" => "Daňové priznanie k dani z pridanej hodnoty (platné od 1.7.2025)",
            "encoding" => "Base64",
            "id" => "ff091265-69ef-4da7-8aec-fb32c1e77afb",
            "signed" => false,
            "mime_type" => "application/xml",
            "name" => "DPHv25",
            "content" => "<XYZ123></XYZ123>"
          }
        ]
      },
      "other_attributes" => {} },
      ['1235/2025']

    Fs::Message.stub :create_outbox_message_with_thread!, outbox_message do
      Fs::DownloadSentMessageJob.new.perform('1235/2025', message_draft: message_draft, fs_client: fs_client)
    end
  end
end
