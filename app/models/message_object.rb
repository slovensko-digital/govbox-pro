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
  has_many :nested_message_objects, inverse_of: :message_object, dependent: :destroy
  has_many :message_objects_tags, dependent: :destroy
  has_many :tags, through: :message_objects_tags

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

  def mark_signed_by_user(user)
    # object, user_signed_tag
    message_objects_tags.find_or_create_by!(tag: user.signed_by_tag)
    message_objects_tags.find_by(tag: user.signature_requested_from_tag)&.destroy

    # object, signed_tag
    unless has_signature_request_from_tags?
      message_objects_tags.find_or_create_by!(tag: user.tenant.signed_tag)
      message_objects_tags.find_by(tag: user.tenant.signature_requested_tag)&.destroy
    end

    has_the_user_signature_requests_tags_within_thread = MessageObjectsTag.
      joins(:tag, message_object: { message: :thread }).
      where(message_threads: { id: message.thread }).
      where(tag: user.signature_requested_from_tag).exists?

    # thread, user_signed_tag
    unless has_the_user_signature_requests_tags_within_thread
      message.thread.message_threads_tags.find_or_create_by!(tag: user.signed_by_tag)
      message.thread.message_threads_tags.find_by(tag: user.signature_requested_from_tag)&.destroy
    end

    has_any_signature_requests_tags_within_thread = MessageObjectsTag.
      joins(:tag, message_object: { message: :thread }).
      where(message_threads: { id: message.thread }).
      where(tag: { type: SignatureRequestedFromTag.to_s }).exists?

    # thread, signed_tag
    unless has_any_signature_requests_tags_within_thread
      message.thread.message_threads_tags.find_or_create_by!(tag: user.tenant.signed_tag)
      message.thread.message_threads_tags.find_by(tag: user.tenant.signature_requested_tag)&.destroy
    end
  end

  def add_signature_requested_from_user(user)
    # done, if already signed by user
    return if tags.exists?(id: user.signed_by_tag)

    # object, user_signature_requested_tag
    message_objects_tags.find_or_create_by!(tag: user.signature_requested_from_tag)

    # object, signature_requested_tag
    message_objects_tags.find_or_create_by!(tag: user.tenant.signature_requested_tag)
    message_objects_tags.find_by(tag: user.tenant.signed_tag)&.destroy

    # thread, user_signature_requested_tag
    message.thread.message_threads_tags.find_or_create_by!(tag: user.signature_requested_from_tag)
    message.thread.message_threads_tags.find_by(tag: user.signed_by_tag)&.destroy

    # thread, signature_requested_tag
    message.thread.message_threads_tags.find_or_create_by!(tag: user.tenant.signature_requested_tag)
    message.thread.message_threads_tags.find_by(tag: user.tenant.signed_tag)&.destroy
  end

  # TODO use user interface and handle edge cases
  def remove_signature_requested_from_tag(tag)
    remove_cascading_tag(tag)
    remove_cascading_tag(tag.tenant.signature_requested_tag) unless has_signature_request_from_tags?
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

  def has_signature_request_from_tags?
    message_objects_tags.joins(:tag).where(tag: { type: SignatureRequestedFromTag.to_s }).exists?
  end

  private

  def allowed_mime_type?
    errors.add(:mime_type, "of #{name} object is disallowed, allowed_mime_types: #{Utils::EXTENSIONS_ALLOW_LIST.join(", ")}") unless mimetype
  end

  def add_cascading_tag(tag)
    message_objects_tags.find_or_create_by!(tag: tag)
    message.thread.message_threads_tags.find_or_create_by!(tag: tag)
  end

  def remove_cascading_tag(tag)
    message_objects_tags.find_by(tag: tag)&.destroy

    thread = message.thread

    same_tag_on_other_thread_object = MessageObjectsTag.
      joins(:tag, message_object: { message: :thread }).
      where(message_threads: { id: thread }).
      where(tag: tag).exists?

    message.thread.message_threads_tags.find_by(tag: tag)&.destroy unless same_tag_on_other_thread_object
  end
end
