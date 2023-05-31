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
    f = Folder.find_or_create_by(
      name: "Inbox",
      box_id: govbox_message.box.id
    ) # TODO create folder for threads

    thread = govbox_message.box.message_threads.find_or_create_by_merge_uuid!(
      merge_uuid: govbox_message.correlation_id,
      folder: f,
      title: "todo thread name #{govbox_message.box.message_threads.count}", # TODO
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
