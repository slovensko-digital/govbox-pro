class Fs::DownloadSentMessageJob < ApplicationJob
  def perform(fs_message_id, box, fs_client: FsEnvironment.fs_client)
    fs_api = fs_client.api(api_connection: box.api_connection, box: box)

    raw_message = fs_api.fetch_sent_message(fs_message_id)
    message_draft = box.messages.where(type: 'Fs::MessageDraft').where("metadata ->> 'fs_message_id' = ?", fs_message_id).take

    message = MessageThread.with_advisory_lock!(message_draft.thread.merge_identifiers, transaction: true, timeout_seconds: 10) do
      message = Message.create(
        uuid: message_draft.uuid,
        title: raw_message['submission_type_name'],
        sender_name: raw_message['subject'],
        recipient_name: 'Finančná správa',
        delivered_at: Time.parse(raw_message['created_at']),
        replyable: false,
        collapsed: true,
        outbox: true,
        metadata: {
          "fs_form_id": message_draft.metadata['fs_form_id'],
          "dic": raw_message['dic']
        },
      )

      message.thread = box.message_threads.find_or_create_by_merge_uuid!(
        box: box,
        merge_uuid: message_draft.thread.merge_identifiers.first.uuid,
        title: message.title,
        delivered_at: message.delivered_at
      )

      message_draft.destroy

      message.save!
      message
    end

    create_message_objects(message, raw_message)
    build_html_visualization(message)

    EventBus.publish(:message_created, message)
  end

  def create_message_objects(message, raw_message)
    raw_message["objects"].each do |raw_object|
      message_object_type = 'FORM'
      visualizable = (message_object_type == "FORM" && message.html_visualization.present?) ? true : nil
      tags = raw_object["signed"] ? [message.thread.box.tenant.signed_externally_tag!] : []

      message_object = message.objects.create!(
        mimetype: raw_object["mime_type"],
        is_signed: true, # TODO nejako detegovat
        object_type: message_object_type,
        visualizable: visualizable,
        tags: tags
      )

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

  def build_html_visualization(message)
    return message.html_visualization if message.html_visualization.present?

    return unless message.form&.xslt_txt
    return unless message.form_object&.unsigned_content

    template = Nokogiri::XSLT(message.form.xslt_txt)
    message.update(html_visualization: template.transform(message.form_object.xml_unsigned_content))
  end
end
