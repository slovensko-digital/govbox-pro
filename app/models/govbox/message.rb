class Govbox::Message < ApplicationRecord
  belongs_to :box
  belongs_to :folder, class_name: 'Govbox::Folder'

  def self.create_message_with_thread!(govbox_message)
    box = folder.box
    folder = Folder.create! # TODO somehow
    thread = box.message_threads.find_or_create_by_merge_uuid!(
      merge_uuid: govbox_message.correlation_id,
      folder: folder,
      title: govbox_message.title,
      delivered_at: govbox_message.delivered_at,
    )

    msg = thread.messages.find_or_create_by_uuid!(
      uuid: govbox_message.message_id,
    )

    govbox_message.parse_objects.each do |govbox_object|
      msg.objects.find_or_create_by_uuid!(
        uuid: govbox_object.uuid,
        # TODO rest
      )
    end
  end

  def parse_objects
    # TODO parse objects and return govbox_objects
    []
  end
end
