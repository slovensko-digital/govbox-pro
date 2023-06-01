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

  def self.create_message_thread!(govbox_message, message)
    folder = Folder.find_or_create_by!(
      name: "Inbox",
      box_id: govbox_message.box.id
    ) # TODO create folder for threads

    message_thread = MessageThread.find_or_create_by(
      merge_uuids: "{#{govbox_message.correlation_id}}"
    )

    message_thread.update!(
      folder: folder,
      title: message.title,
      original_title: message.title, # TODO
      delivered_at: govbox_message.delivered_at
    )

    message.message_thread = message_thread
    message.save!
  end
end
