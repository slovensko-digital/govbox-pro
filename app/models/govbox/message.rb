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
      box_id: govbox_message.box.id
    ) # TODO create folder for threads

    message_thread = MessageThread.find_or_create_by(
      merge_uuids: "{#{govbox_message.correlation_id}}"
    )

    message = self.create_message(govbox_message.payload)

    message_thread.update!(
      folder: folder,
      title: message.title,
      original_title: message.title, # TODO
      delivered_at: govbox_message.delivered_at
    )

    message.message_thread = message_thread
    message.save!

    self.create_message_objects(message, govbox_message.payload)
  end

  private

  def self.create_message(raw_message)
    ::Message.create(
      uuid: raw_message["message_id"],
      title: raw_message["subject"],
      sender_name: raw_message["sender_name"],
      recipient_name: raw_message["recipient_name"],
      delivered_at: Time.parse(raw_message["delivered_at"])
    )
  end

  def self.create_message_objects(message, raw_message)
    raw_message["objects"].each do |raw_object|
      object = message.message_objects.create!(
        name: raw_object["name"],
        mimetype: raw_object["mime_type"],
        is_signed: raw_object["signed"],
        encoding: raw_object["encoding"],
        object_type: raw_object["class"]
      )

      MessageObjectDatum.create!(
        blob: raw_object["content"],
        message_object_id: object.id
      )
    end
  end
end
