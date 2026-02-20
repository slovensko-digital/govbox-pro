require "test_helper"

class Fs::DownloadReceivedMessageJobTest < ActiveJob::TestCase
  test "fetches received ED.DeliveryReport message" do
    outbox_message = messages(:fs_accountants_outbox)

    fs_api = Minitest::Mock.new

    fs_client = Minitest::Mock.new
    fs_client.expect :api, fs_api, **{ api_connection: api_connections(:fs_api_connection1), box: outbox_message.box }

    fs_api.expect :obo_without_delegate, "obo_without_delegate"
    fs_api.expect :fetch_received_message, {
      "created_at"=>"2024-11-11T15:53:59.830Z",
      "message_id" => "12356/2024",
      "submission_type_id" => "123",
      "submission_type_name" => "Daňové priznanie k dani z pridanej hodnoty (platné od 1.7.2025) - riadne",
      "message_type_id" => "DRSR_POPP_v02",
      "message_type_name" => "Informácia o podaní",
      "sent_message_id" => "1234/2024",
      "seen" => true,
      "is_ekr2" => true,
      "status" => "Vybavená",
      "submission_status" => "Prijaté a potvrdené",
      "dic" => "9988665533",
      "subject" => "XY s. r. o.",
      "submitting_subject" => "XYZ 123",
      "submission_created_at"=>"2024-11-11T15:53:58.721Z",
      "period" => "092024",
      "dismissal_reason"=>nil,
      "submission_verification_status"=>{"name"=>"Platné", "description"=>"Overenie platnosti podpisov podania bolo ukončené. Všetky podpisy sú platné."},
      "message_container" => {
        "message_id" => "78b6c5f1-02e9-47ad-9fab-47f03aef1e65",
        "sender_id" => "FSSR",
        "recipient_id" => "123",
        "message_type" => "ED.DeliveryReport",
        "subject" => "Doručenka k eDANEjava",
        "objects" => [
          {
            "class" => "FORM",
            "description"=>"DeliveryReport",
            "encoding" => "Base64",
            "id" => "51e13e67-316a-48cb-934c-c63b20ac5b5a",
            "signed" => true,
            "mime_type" => "application/vnd.etsi.asic-e+zip",
            "name" => "DeliveryReport",
            "content" => "UEsFBgAAAAAAAAAAAAAAAAAAAAAAAA=="
          }
        ]
      },
      "other_attributes" => {} },
      ['12356/2024']

    Fs::DownloadReceivedMessageJob.new.perform('12356/2024', box: outbox_message.box, fs_client: fs_client)

    message = Message.last

    assert_not message.outbox
    assert_equal 'Informácia o podaní', message.title
    assert_equal 'Finančná správa', message.sender_name
    assert_equal '12356/2024', message.metadata['fs_message_id']
    assert_equal 'Prijaté a potvrdené', message.metadata['fs_submission_status']
    assert_equal 'Platné', message.metadata['fs_submission_verification_status']['name']
    assert_equal 'Overenie platnosti podpisov podania bolo ukončené. Všetky podpisy sú platné.', message.metadata['fs_submission_verification_status']['description']
  end

  test "fetches other received messages" do
    outbox_message = messages(:fs_accountants_outbox)

    fs_api = Minitest::Mock.new

    fs_client = Minitest::Mock.new
    fs_client.expect :api, fs_api, **{ api_connection: api_connections(:fs_api_connection1), box: outbox_message.box }

    fs_api.expect :obo_without_delegate, "obo_without_delegate"
    fs_api.expect :fetch_received_message, {
      "created_at"=>"2024-11-12T08:43:10.136Z",
      "message_id" => "Z02031014/2024",
      "submission_type_id" => "3055",
      "submission_type_name" => "Daňové priznanie k dani z pridanej hodnoty (platné od 1.7.2025) - riadne",
      "message_type_id" => "80149",
      "message_type_name" => "Informácia o vytvorení platobného príkazu",
      "sent_message_id" => "1234/2024",
      "seen" => true,
      "is_ekr2" => true,
      "status" => "Vybavená",
      "submission_status" => "Prijaté a potvrdené",
      "dic" => "9988665533",
      "subject" => "XY s. r. o.",
      "submitting_subject" => "XYZ 123",
      "submission_created_at"=>"2024-11-11T15:53:58.721Z",
      "period" => "092024",
      "dismissal_reason"=>nil,
      "message_container" => {
        "message_id" => "727dc3ee-2dfe-417b-be73-b99baab48258",
        "sender_id" => "MIMEP",
        "recipient_id" => "123",
        "message_type" => "80149",
        "subject" => nil,
        "objects" => [
          {
            "class" => "FORM",
            "description"=>"Informácia o vytvorení platobného príkazu",
            "encoding" => "Base64",
            "id" => "5dc98201-3a1b-4a6c-8e0f-541df12a8bbb",
            "signed" => true,
            "mime_type" => "application/vnd.etsi.asic-e+zip",
            "name" => "IVPnu",
            "content" => "UEsFBgAAAAAAAAAAAAAAAAAAAAAAAA=="
          }
        ]
      },
      "other_attributes" => {} },
                  ['Z02031014/2024']

    Fs::DownloadReceivedMessageJob.new.perform('Z02031014/2024', box: outbox_message.box, fs_client: fs_client)

    message = Message.last

    assert_not message.outbox
    assert_equal 'Informácia o vytvorení platobného príkazu', message.title
    assert_equal 'Finančná správa', message.sender_name
    assert_equal 'Z02031014/2024', message.metadata['fs_message_id']
  end

  test "does not fetch received message unless ED.DeliveryReport signatures verified" do
    outbox_message = messages(:fs_accountants_outbox)

    fs_api = Minitest::Mock.new

    fs_client = Minitest::Mock.new
    fs_client.expect :api, fs_api, **{ api_connection: api_connections(:fs_api_connection1), box: outbox_message.box }

    fs_api.expect :obo_without_delegate, "obo_without_delegate"
    fs_api.expect :fetch_received_message, {
      "created_at"=>"2024-11-11T15:53:59.830Z",
      "message_id" => "12356/2024",
      "submission_type_id" => "123",
      "submission_type_name" => "Daňové priznanie k dani z pridanej hodnoty (platné od 1.7.2025) - riadne",
      "message_type_id" => "DRSR_POPP_v02",
      "message_type_name" => "Informácia o podaní",
      "sent_message_id" => "1234/2024",
      "seen" => true,
      "is_ekr2" => true,
      "status" => "Vybavená",
      "submission_status" => "Prijaté a potvrdené",
      "dic" => "9988665533",
      "subject" => "XY s. r. o.",
      "submitting_subject" => "XYZ 123",
      "submission_created_at"=>"2024-11-11T15:53:58.721Z",
      "period" => "092024",
      "dismissal_reason"=>nil,
      "submission_verification_status"=>{"name"=>"Predbežne platné", "description"=>"Overenie platnosti podpisov podania ešte nebolo ukončené. Podpisy sú zatiaľ považované za predbežne platné."},
      "message_container" => {
        "message_id" => "78b6c5f1-02e9-47ad-9fab-47f03aef1e65",
        "sender_id" => "FSSR",
        "recipient_id" => "123",
        "message_type" => "ED.DeliveryReport",
        "subject" => "Doručenka k eDANEjava",
        "objects" => [
          {
            "class" => "FORM",
            "description"=>"DeliveryReport",
            "encoding" => "Base64",
            "id" => "51e13e67-316a-48cb-934c-c63b20ac5b5a",
            "signed" => true,
            "mime_type" => "application/vnd.etsi.asic-e+zip",
            "name" => "DeliveryReport",
            "content" => "UEsFBgAAAAAAAAAAAAAAAAAAAAAAAA=="
          }
        ]
      },
      "other_attributes" => {} },
      ['12356/2024']

    assert_raise('Signatures not yet verified!') do
      Fs::DownloadReceivedMessageJob.new.perform('12356/2024', box: outbox_message.box, fs_client: fs_client)
    end
  end
end
