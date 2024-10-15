class Fs::Message
  FS_SUBJECT_NAME = 'Finančná správa'

  def self.create_outbox_message_with_thread!(box, raw_message, associated_message_draft: nil)
    message = nil

    # TODO ako zistit ktory merge identifier patri k tomuto draftu? Co ak bude mergnutych dokopy viac vlakien?
    merge_identifier = associated_message_draft&.thread&.merge_identifiers&.first&.uuid || SecureRandom.uuid

    MessageThread.with_advisory_lock!(merge_identifier, transaction: true, timeout_seconds: 10) do
      message = create_outbox_message(raw_message)

      message.thread = box.message_threads.find_or_create_by_merge_uuid!(
        box: box,
        merge_uuid: merge_identifier,
        title: message.title,
        delivered_at: message.delivered_at
      )

      associated_message_draft&.destroy

      message.save!
    end

    create_message_objects(message, raw_message)

    EventBus.publish(:message_created, message)
  end


  def collapsed?
    # TODO odoslana sprava s potvrdenkou by mohla byt collapsed
    true
  end

  private

  def self.create_outbox_message(raw_message, associated_message_draft: nil)
    Message.create(
      uuid: associated_message_draft&.uuid || SecureRandom.uuid,
      title: raw_message['submission_type_name'],
      sender_name: raw_message['subject'],
      recipient_name: FS_SUBJECT_NAME,
      delivered_at: Time.parse(raw_message['created_at']),
      replyable: false,
      collapsed: collapsed?,
      outbox: true,
      metadata: {
        "fs_form_id": (associated_message_draft.metadata['fs_form_id'] if associated_message_draft),
        "dic": raw_message['dic']
      },
    )
  end

  def self.create_message_objects(message, raw_message)
    raw_message["objects"].each do |raw_object|
      # TODO mozu byt aj ine typy objektov? asi ano, vieme to identifikovat?
      message_object_type = 'FORM'
      visualizable = (message_object_type == "FORM" && message.html_visualization.present?) ? true : nil
      tags = raw_object["signed"] ? [message.thread.box.tenant.signed_externally_tag!] : []

      message_object = message.objects.create!(
        mimetype: raw_object["mime_type"],
        is_signed: false, # TODO nejako detegovat
        object_type: message_object_type,
        visualizable: visualizable,
        tags: tags
      )

      # TODO toto je unsigned_content, presunut logiku tam a co ma byt ulozene tu?
      if raw_object["encoding"] == "Base64"
        unzipped_message_object_content = ::Utils.unzip(Base64.decode64(raw_object["xml_data"]))
        xml_content = Nokogiri::XML(Base64.decode64(unzipped_message_object_content))
        message_object_content = xml_content.xpath('*:XMLDataContainer/*:XMLData/*').to_xml do |config|
          config.noblanks
        end if xml_content.xpath('*:XMLDataContainer/*:XMLData').any?
      else
        message_object_content = raw_object["xml_data"]
      end

      MessageObjectDatum.create!(
        blob: message_object_content,
        message_object_id: message_object.id
      )
    end
  end
end
