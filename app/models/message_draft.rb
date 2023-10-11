# == Schema Information
#
# Table name: messages
#
#  id                                          :integer          not null, primary key
#  uuid                                        :uuid             not null
#  title                                       :string           not null
#  message_thread_id                           :integer          not null
#  sender_name                                 :string
#  recipient_name                              :string
#  html_visualization                          :text
#  metadata                                    :json
#  read                                        :boolean          not null, default: false
#  replyable                                   :boolean          not null, default: true
#  delivered_at                                :datetime         not null
#  import_id                                   :integer
#  author_id                                   :integer
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class MessageDraft < Message
  belongs_to :import, class_name: 'MessageDraftsImport', foreign_key: :import_id, optional: true

  after_destroy { self.thread.destroy! if self.thread.messages.none? }

  GENERAL_AGENDA_POSP_ID = "App.GeneralAgenda"
  GENERAL_AGENDA_POSP_VERSION = "1.9"
  GENERAL_AGENDA_MESSAGE_TYPE = "App.GeneralAgenda"

  with_options on: :validate_data do |message_draft|
    message_draft.validates :uuid, format: { with: Utils::UUID_PATTERN }, allow_blank: false
    message_draft.validate :validate_metadata
    message_draft.validate :validate_form
    message_draft.validate :validate_objects
  end

  def self.create_message_reply(original_message: , author:)
    message_draft = MessageDraft.create!(
      uuid: SecureRandom.uuid,
      thread: original_message.thread,
      sender_name: original_message.recipient_name,
      recipient_name: original_message.sender_name,
      read: true,
      delivered_at: Time.now,
      author: author,
      metadata: {
        "recipient_uri": original_message.metadata["sender_uri"],
        "posp_id": GENERAL_AGENDA_POSP_ID,
        "posp_version": GENERAL_AGENDA_POSP_VERSION,
        "message_type": GENERAL_AGENDA_MESSAGE_TYPE,
        "correlation_id": original_message.metadata["correlation_id"],
        "reference_id": original_message.uuid,
        "original_message_id": original_message.id,
        "status": "created"
      }
    )

    drafts_tag = Tag.find_or_create_by!(name: "Drafts", tenant: message_draft.thread.box.tenant)

    message_draft.thread.add_tag(drafts_tag)

    message_draft
  end

  def update_content(title:, body:)
    self.title = title
    metadata["message_body"] = body
    save!

    return unless title.present? && body.present?

    # TODO clean the domain (no UPVS stuff)
    if form
      form.message_object_datum.update(
        blob: Upvs::FormBuilder.build_general_agenda_xml(subject: title, body: body)
      )
    else
      form = MessageObject.create(
        message_id: id,
        name: "form.xml",
        mimetype: "application/x-eform-xml",
        object_type: "FORM",
        is_signed: false
      )

      form.message_object_datum = MessageObjectDatum.create(
        message_object: form,
        blob: Upvs::FormBuilder.build_general_agenda_xml(subject: title, body: body)
      )
    end

    self.reload
  end

  def editable?
    metadata["posp_id"] == GENERAL_AGENDA_POSP_ID && !form&.is_signed? && not_yet_submitted?
  end

  def custom_visualization?
    metadata["posp_id"] == GENERAL_AGENDA_POSP_ID
  end

  def submittable?
    form.present? && objects.to_be_signed.all? { |o| o.is_signed? } && !invalid? && not_yet_submitted?
  end

  def not_yet_submitted?
    !%w[being_submitted submitted].include? metadata["status"]
  end

  def being_submitted?
    metadata["status"] == "being_submitted"
  end

  def submitted?
    metadata["status"] == "submitted"
  end

  def being_submitted!
    metadata["status"] = "being_submitted"
    save!
  end
  
  def invalid?
    metadata["status"] == "invalid"
  end

  def original_message
    Message.find(metadata["original_message_id"]) if metadata["original_message_id"]
  end

  private

  def validate_metadata
    errors.add(:metadata, "No recipient URI") unless metadata["recipient_uri"].present?
    errors.add(:metadata, "No posp ID") unless metadata["posp_id"].present?
    errors.add(:metadata, "No posp version") unless metadata["posp_version"].present?
    errors.add(:metadata, "No message type") unless metadata["message_type"].present?
    errors.add(:metadata, "No correlation ID") unless metadata["correlation_id"].present?
    errors.add(:metadata, "Correlation ID must be UUID") unless metadata["correlation_id"]&.match?(Utils::UUID_PATTERN)
  end

  def validate_form
    forms = objects.select { |o| o.form? }

    if objects.size == 0
      errors.add(:objects, "No objects found for draft")
    elsif forms.size != 1
      errors.add(:objects, "Draft has to contain exactly one form")
    end
  end

  def validate_objects
    objects.each do |object|
      object.valid?(:validate_data)
      errors.merge!(object.errors)
    end
  end
end
