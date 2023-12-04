# == Schema Information
#
# Table name: message_objects
#
#  id           :bigint           not null, primary key
#  is_signed    :boolean
#  mimetype     :string
#  name         :string
#  object_type  :string           not null
#  to_be_signed :boolean          default(FALSE), not null
#  visualizable :boolean
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  message_id   :bigint           not null
#
class MessageObject < ApplicationRecord
  belongs_to :message, inverse_of: :objects
  has_one :message_object_datum, dependent: :destroy
  has_many :nested_message_objects, inverse_of: :message_object

  scope :unsigned, -> { where(is_signed: false) }
  scope :to_be_signed, -> { where(to_be_signed: true) }
  scope :should_be_signed, -> { where(to_be_signed: true, is_signed: false) }

  validates :name, presence: true, on: :validate_data
  validate :allowed_mime_type?, on: :validate_data

  after_update ->(message_object) { EventBus.publish(:message_object_changed, message_object) }

  def self.create_message_objects(message, objects)
    objects.each do |raw_object|
      message_object_content = raw_object.read.force_encoding("UTF-8")

      message_object = MessageObject.create!(
        message: message,
        name: raw_object.original_filename,
        mimetype: Utils.file_mime_type_by_name(entry_name: raw_object.original_filename),
        is_signed: Utils.is_signed?(entry_name: raw_object.original_filename, content: message_object_content),
        object_type: "ATTACHMENT"
      )

      MessageObjectDatum.create!(
        message_object: message_object,
        blob: message_object_content
      )
    end
  end

  def content
    message_object_datum&.blob
  end

  def form?
    object_type == "FORM"
  end

  def signable?
    # TODO: vymazat druhu podmienku po povoleni viacnasobneho podpisovania
    message.draft? && !is_signed
  end

  def asice?
    mimetype == 'application/vnd.etsi.asic-e+zip'
  end

  def destroyable?
    # TODO: avoid loading message association if we have
    message.draft? && message.not_yet_submitted? && !form?
  end

  def remove_signature
    return false unless form?
    return false unless is_signed

    unsigned_object = nested_message_objects&.first
    return false unless unsigned_object

    transaction do
      update(name: unsigned_object.name, mimetype: unsigned_object.mimetype, is_signed: false)
      message_object_datum.update(blob: unsigned_object.content)
      unsigned_object.destroy
    end
  end

  private

  def allowed_mime_type?
    errors.add(:mime_type, "of #{name} object is disallowed, allowed_mime_types: #{Utils::EXTENSIONS_ALLOW_LIST.join(", ")}") unless mimetype
  end
end
