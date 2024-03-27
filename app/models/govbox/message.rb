# == Schema Information
#
# Table name: govbox_messages
#
#  id               :bigint           not null, primary key
#  delivered_at     :datetime         not null
#  edesk_class      :string           not null
#  payload          :json             not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  correlation_id   :uuid             not null
#  edesk_message_id :bigint           not null
#  folder_id        :bigint           not null
#  message_id       :uuid             not null
#
class Govbox::Message < ApplicationRecord
  belongs_to :folder, class_name: 'Govbox::Folder'

  delegate :box, to: :folder

  EGOV_DOCUMENT_CLASS = 'EGOV_DOCUMENT'
  EGOV_NOTIFICATION_CLASS = 'EGOV_NOTIFICATION'
  COLLAPSED_BY_DEFAULT_MESSAGE_CLASSES = ['ED_DELIVERY_REPORT', 'POSTING_CONFIRMATION', 'POSTING_INFORMATION']

  DELIVERY_NOTIFICATION_TAG = 'delivery_notification'

  def self.create_message_with_thread!(govbox_message)
    message = nil

    MessageThread.with_advisory_lock!(govbox_message.correlation_id, transaction: true, timeout_seconds: 10) do
      message = create_message(govbox_message)

      message.thread = govbox_message.box.message_threads.find_or_create_by_merge_uuid!(
        box: govbox_message.box,
        merge_uuid: govbox_message.correlation_id,
        title: message.metadata.dig("delivery_notification", "consignment", "subject").presence || message.title,
        delivered_at: govbox_message.delivered_at
      )

      message.save!

      add_upvs_related_tags(message, govbox_message)
    end

    create_message_objects(message, govbox_message.payload)

    EventBus.publish(:message_thread_created, message.thread) if message.thread.previously_new_record?
    EventBus.publish(:message_created, message)

    message
  end

  def replyable?
    folder.inbox? && [EGOV_DOCUMENT_CLASS, EGOV_NOTIFICATION_CLASS].include?(payload["class"])
  end

  def collapsed?
    payload["class"].in?(COLLAPSED_BY_DEFAULT_MESSAGE_CLASSES)
  end

  def delivery_notification
    payload["delivery_notification"]
  end

  private

  def self.create_message(govbox_message)
    raw_message = govbox_message.payload

    sender_name = raw_message["sender_name"]
    recipient_name = raw_message["recipient_name"]

    if govbox_message.payload["sender_uri"] == govbox_message.folder.box.uri
      sender_name ||= govbox_message.folder.box.name
    elsif govbox_message.payload["recipient_uri"] == govbox_message.folder.box.uri
      recipient_name ||= govbox_message.folder.box.name
    end

    ::Message.create(
      uuid: raw_message["message_id"],
      title: [raw_message["subject"], raw_message.dig("general_agenda", "subject")].compact.join(' - '),
      sender_name: sender_name,
      recipient_name: recipient_name,
      delivered_at: Time.parse(raw_message["delivered_at"]),
      html_visualization: raw_message["original_html"],
      replyable: govbox_message.replyable?,
      collapsed: govbox_message.collapsed?,
      outbox: govbox_message.folder.outbox?,
      metadata: {
        "correlation_id": govbox_message.payload["correlation_id"],
        "reference_id": govbox_message.payload["reference_id"],
        "sender_uri": govbox_message.payload["sender_uri"],
        "edesk_class": govbox_message.payload["class"],
        "delivery_notification": govbox_message.delivery_notification
      }
    )
  end

  def self.create_message_objects(message, raw_message)
    raw_message["objects"].each do |raw_object|
      message_object_type = raw_object["class"]
      visualizable = (message_object_type == "FORM" && message.html_visualization.present?) ? true : nil
      tags = raw_object["signed"] ? [message.thread.box.tenant.signed_externally_tag!] : []

      message_object = message.objects.create!(
        name: raw_object["name"],
        mimetype: raw_object["mime_type"],
        is_signed: raw_object["signed"],
        object_type: message_object_type,
        visualizable: visualizable,
        tags: tags
      )

      if raw_object["encoding"] == "Base64"
        message_object_content = Base64.decode64(raw_object["content"])
      else
        message_object_content = raw_object["content"]
      end

      MessageObjectDatum.create!(
        blob: message_object_content,
        message_object_id: message_object.id
      )
    end
  end

  def self.add_upvs_related_tags(message, govbox_message)
    upvs_tag = SimpleTag.find_or_create_by!(
      external_name: "slovensko.sk:#{govbox_message.folder.full_name}",
      tenant: govbox_message.box.tenant
    ) do |tag|
      tag.name = "slovensko.sk:#{govbox_message.folder.full_name}"
      tag.visible = !govbox_message.folder.system?
    end
    message.add_cascading_tag(upvs_tag)

    add_delivery_notification_tag(message) if message.can_be_authorized?
  end

  def self.add_delivery_notification_tag(message)
    message.add_cascading_tag(delivery_notification_tag(message))
  end

  def self.remove_delivery_notification_tag(message)
    message.remove_cascading_tag(delivery_notification_tag(message))
  end

  def self.delivery_notification_tag(message)
    Upvs::DeliveryNotificationTag.find_or_create_for_tenant!(message.thread.box.tenant)
  end
end
