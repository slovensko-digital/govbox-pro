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
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Govbox::Message < ApplicationRecord
  belongs_to :folder, class_name: 'Govbox::Folder'

  delegate :box, to: :folder

  def self.create_message_with_thread!(govbox_message)
    folder = Folder.find_or_create_by!(
      name: "Inbox",
      box: govbox_message.box
    ) # TODO create folder for threads

    message_thread = MessageThread.find_or_create_by(
      merge_uuids: "{#{govbox_message.correlation_id}}"
    )

    message = self.create_message_with_tag(govbox_message)

    message_thread.update!(
      folder: folder,
      title: message.title,
      original_title: message.title, # TODO
      delivered_at: govbox_message.delivered_at
    )

    message.thread = message_thread
    message.save!

    self.create_message_objects(message, govbox_message.payload)
  end

  private

  def self.create_message_with_tag(govbox_message)
    message_tag = Tag.find_or_create_by!(
      name: "slovensko.sk:#{govbox_message.folder.full_name}",
      tenant: govbox_message.box.tenant
    )

    raw_message = govbox_message.payload

    message = ::Message.create(
      uuid: raw_message["message_id"],
      title: raw_message["subject"],
      sender_name: raw_message["sender_name"],
      recipient_name: raw_message["recipient_name"],
      delivered_at: Time.parse(raw_message["delivered_at"]),
      html_visualization: raw_message["original_html"]
    )

    message.tags << message_tag
    message
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
end
