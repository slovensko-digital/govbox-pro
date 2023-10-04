# == Schema Information
#
# Table name: message_objects
#
#  id                                          :integer          not null, primary key
#  name                                        :string           not null
#  mimetype                                    :string
#  is_signed                                   :boolean
#  to_be_signed                                :boolean          not null, default: false
#  object_type                                 :string           not null
#  message_id                                  :integer          not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class MessageObject < ApplicationRecord
  belongs_to :message
  has_one :message_object_datum, dependent: :destroy

  scope :unsigned, -> { where('is_signed = false') }
  scope :to_be_signed, -> { where('to_be_signed = true') }
  scope :should_be_signed, -> { where('to_be_signed = true AND is_signed = false') }

  validates :name, presence: true, on: :validate_data
  validate :allowed_mime_type?, on: :validate_data

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

  def content
    message_object_datum.blob
  end

  def form?
    object_type == "FORM"
  end

  def signable?
    # TODO vymazat druhu podmienku po povoleni viacnasobneho podpisovania
    message.is_a?(MessageDraft) && !is_signed
  end

  def destroyable?
    message.is_a?(MessageDraft) && message.not_yet_submitted? && !form?
  end

  private

  def allowed_mime_type?
    errors.add(:mime_type, "of #{name} object is disallowed, allowed_mime_types: #{Utils::EXTENSIONS_ALLOW_LIST.join(', ')}") unless mimetype
  end
end
