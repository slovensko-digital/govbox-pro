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
  include PdfVisualizationOperations

  belongs_to :message, inverse_of: :objects
  has_one :message_object_datum, dependent: :destroy
  has_many :nested_message_objects, inverse_of: :message_object, dependent: :destroy
  has_many :message_objects_tags, dependent: :destroy
  has_many :tags, through: :message_objects_tags
  has_one :archived_object, dependent: :destroy

  scope :unsigned, -> { where(is_signed: false) }
  scope :to_be_signed, -> { where(to_be_signed: true) }
  scope :should_be_signed, -> { where(to_be_signed: true, is_signed: false) }

  validates :name, presence: { message: "Name can't be blank" }, on: :validate_data
  validate :allowed_mimetype?, on: :validate_data

  after_create ->(message_object) { message_object.fill_missing_info }
  after_update ->(message_object) { EventBus.publish(:message_object_changed, message_object) }
  before_destroy :remove_object_related_tags_from_thread, prepend: true

  def self.create_message_objects(message, objects)
    objects.each do |raw_object|
      message_object_content = raw_object.read.force_encoding("UTF-8")

      is_signed = Utils.is_signed?(entry_name: raw_object.original_filename, content: message_object_content)
      tags = is_signed ? [message.thread.box.tenant.signed_externally_tag!] : []

      message_object = MessageObject.create!(
        message: message,
        name: raw_object.original_filename,
        mimetype: Utils.file_mimetype_by_name(entry_name: raw_object.original_filename),
        is_signed: is_signed,
        object_type: "ATTACHMENT",
        tags: tags
      )

      MessageObjectDatum.create!(
        message_object: message_object,
        blob: message_object_content
      )
    end
  end

  def mark_signed_by_user(user)
    assign_tag(user.signed_by_tag)
    unassign_tag(user.signature_requested_from_tag)
    unassign_tag(user.tenant.signer_group.signature_requested_from_tag)

    thread.mark_signed_by_user(user)
  end

  def add_signature_requested_from_group(group)
    return if has_tag?(group.signed_by_tag)

    assign_tag(group.signature_requested_from_tag)
    thread.add_signature_requested_from_group(group)
  end

  def remove_signature_requested_from_group(group)
    return unless has_tag?(group.signature_requested_from_tag)

    unassign_tag(group.signature_requested_from_tag)
    thread.remove_signature_requested_from_group(group)
  end

  def content
    message_object_datum&.blob
  end

  def unsigned_content(mimetypes: Utils::XML_MIMETYPES)
    if is_signed
      nested_message_objects&.where("mimetype ILIKE ANY ( array[?] )", mimetypes.map { |val| "#{val}%" })&.first&.content
    else
      content
    end
  end

  def form?
    object_type == "FORM"
  end

  def asice?
    Utils::ASICE_MIMETYPES.include?(mimetype)
  end

  def destroyable?
    # TODO: avoid loading message association if we have
    message.draft? && message.not_yet_submitted? && !form?
  end

  def archived?
    archived_object.present?
  end

  def downloadable_archived_object?
    archived_object&.archived?
  end

  def assign_tag(tag)
    message_objects_tags.find_or_create_by!(tag: tag)
  end

  def fill_missing_info
    update(name: name + Utils.file_extension_by_mimetype(mimetype).to_s) if Utils.file_name_without_extension?(self)
    update(mimetype: Utils.file_mimetype_by_name(entry_name: name)) if mimetype == Utils::OCTET_STREAM_MIMETYPE
  end

  def pdf?
    mimetype == Utils::PDF_MIMETYPE
  end

  def xml?
    Utils::XML_MIMETYPES.any? { |xml_mimetype| xml_mimetype == Utils.mimetype_without_optional_params(mimetype) }
  end

  private

  def allowed_mimetype?
    if mimetype
      errors.add(:mimetype, "MimeType of #{name} object is disallowed, allowed mimetypes: #{Utils::MIMETYPES_ALLOW_LIST.join(", ")}") unless Utils::MIMETYPES_ALLOW_LIST.include?(mimetype)
    else
      errors.add(:mimetype, "MimeType of #{name} object is disallowed, allowed file types: #{Utils::EXTENSIONS_ALLOW_LIST.join(", ")}")
    end
  end

  def has_tag?(tag)
    message_objects_tags.joins(:tag).where(tag: tag).exists?
  end

  def unassign_tag(tag)
    message_objects_tags.find_by(tag: tag)&.destroy
  end

  def thread
    message.thread
  end

  def remove_object_related_tags_from_thread
    tags.each do |tag|
      message.thread.unassign_tag(tag) unless other_thread_objects_include_tag?(tag)
    end

    message.thread.unassign_tag(message.tenant.signed_tag!) unless message.thread.tags.reload.where(type: SignedByTag.to_s).any?
  end

  def other_thread_objects_include_tag?(tag)
    message.thread.objects.excluding(self).joins(:tags).where(tags: { id: tag.id }).any?
  end
end
