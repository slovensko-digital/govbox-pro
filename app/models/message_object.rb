# == Schema Information
#
# Table name: message_objects
#
#  id                                          :integer          not null, primary key
#  name                                        :string           not null
#  mimetype                                    :string           not null
#  is_signed                                   :boolean
#  to_be_signed                                :boolean          not null, default: false
#  object_type                                 :string           not null
#  message_id                                  :integer          not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class MessageObject < ApplicationRecord
  belongs_to :message
  has_one :message_object_datum, dependent: :destroy

  scope :to_be_signed, -> { where('to_be_signed = true') }

  def self.create_message_objects(message, objects)
    objects.each do |raw_object|
      message_object = MessageObject.create!(
        message: message,
        name: raw_object.original_filename,
        mimetype: Utils.detect_mime_type(entry_name: raw_object.original_filename),
        is_signed: Utils.is_signed?(entry_name: raw_object.original_filename),
        object_type: "ATTACHMENT"
      )

      MessageObjectDatum.create!(
        message_object: message_object,
        blob: raw_object.read.force_encoding("UTF-8")
      )
    end
  end

  def form?
    object_type == "FORM"
  end

  def signable?
    message.is_a?(MessageDraft)
  end

  def destroyable?
    message.is_a?(MessageDraft) && !form?
  end
end
