# == Schema Information
#
# Table name: govbox_messages
#
#  id                                          :integer          not null, primary key
#  edesk_message_id                            :integer          not null
#  folder_id                                   :integer          not null
#  message_id                                  :uuid             not null
#  correlation_id                              :uuid             not null
#  delivered_at                                :datetime         not null
#  edesk_class                                 :string           not null
#  body                                        :text             not null
#  payload                                     :json             not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Govbox::Message < ApplicationRecord
  belongs_to :folder, class_name: 'Govbox::Folder'

  delegate :box, to: :folder

  EGOV_DOCUMENT_CLASS = 'EGOV_DOCUMENT'
  EGOV_NOTIFICATION_CLASS = 'EGOV_NOTIFICATION'

  def can_be_replied?
    folder.inbox? && [EGOV_DOCUMENT_CLASS, EGOV_NOTIFICATION_CLASS].include?(payload["class"])
  end

  def self.create_message_with_thread!(govbox_message)
    folder = Folder.find_or_create_by!(
      name: "Inbox",
      box: govbox_message.box
    ) # TODO create folder for threads

    message = self.create_message(govbox_message)

    message.thread = govbox_message.box.message_threads.find_or_create_by_merge_uuid!(
      folder: folder,
      merge_uuid: govbox_message.correlation_id,
      title: message.title,
      delivered_at: govbox_message.delivered_at
    )

    self.create_message_tag(message, govbox_message)

    message.save!

    self.create_message_objects(message, govbox_message.payload)
  end

  private

  def self.create_message(govbox_message)
    raw_message = govbox_message.payload

    ::Message.create(
      uuid: raw_message["message_id"],
      title: raw_message["subject"],
      sender_name: raw_message["sender_name"],
      recipient_name: raw_message["recipient_name"],
      delivered_at: Time.parse(raw_message["delivered_at"]),
      html_visualization: raw_message["original_html"],
      metadata: {
        "correlation_id": govbox_message.payload["correlation_id"],
        "sender_uri": govbox_message.payload["sender_uri"],
        "edesk_class": govbox_message.payload["class"],
        "delivery_notification": govbox_message.payload["delivery_notification"],
        "can_be_replied": govbox_message.can_be_replied?
      }
    )
  end

  def self.create_message_objects(message, raw_message)
    raw_message["objects"].each do |raw_object|
      object = message.objects.create!(
        name: raw_object["name"],
        mimetype: raw_object["mime_type"],
        is_signed: raw_object["signed"],
        object_type: raw_object["class"]
      )

      if raw_object["encoding"] == "Base64"
        object_content = Base64.decode64(raw_object["content"])
      else
        object_content = raw_object["content"]
      end

      MessageObjectDatum.create!(
        blob: object_content,
        message_object_id: object.id
      )
    end
  end

  def self.create_message_tag(message, govbox_message)
    tag = Tag.find_or_create_by!(
      name: "slovensko.sk:#{govbox_message.folder.full_name}",
      tenant: govbox_message.box.tenant,
      visible: !govbox_message.folder.system?
    )

    message.tags << tag
    message.thread.tags << tag unless message.thread.tags.include?(tag)
  end
end
