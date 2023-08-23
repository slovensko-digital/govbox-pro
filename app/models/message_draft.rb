class MessageDraft < Message
  MESSAGE_REPLY_POSP_ID ||= "App.GeneralAgenda"
  MESSAGE_REPLY_POSP_VERSION ||= "1.9"
  MESSAGE_REPLY_MESSAGE_TYPE ||= "App.GeneralAgenda"

  with_options on: :validate_data do |message_draft|
    message_draft.validates :uuid, format: { with: Utils::UUID_PATTERN }, allow_blank: false
    message_draft.validate :validate_metadata
    message_draft.validate :validate_form
    message_draft.validate :validate_objects
  end

  def self.create_message_reply(message)
    MessageDraft.create!(
      uuid: SecureRandom.uuid,
      thread: message.thread,
      sender_name: message.recipient_name,
      recipient_name: message.sender_name,
      read: true,
      delivered_at: Time.now,
      metadata: {
        "recipient_uri": message.metadata["sender_uri"],
        "posp_id": MESSAGE_REPLY_POSP_ID,
        "posp_version": MESSAGE_REPLY_POSP_VERSION,
        "message_type": MESSAGE_REPLY_MESSAGE_TYPE,
        "correlation_id": message.metadata["correlation_id"],
        "reference_id": message.uuid,
        "original_message_id": message.id,
        "status": "created"
      }
    )
  end

  def self.submit(message_draft)
    Govbox::SubmitMessageDraftJob.perform_later(message_draft)

    message_draft.metadata["status"] = "being_submitted"
    message_draft.save!
  end

  def update_content(title:, body:)
    form = objects.select { |o| o.form? }&.first

    unless form
      form = MessageObject.create(
        message_id: id,
        name: "form.xml",
        mimetype: "application/x-eform-xml",
        object_type: "FORM",
        is_signed: false
      )

      form.message_object_datum.create
    end

    form.message_object_datum.update(
      blob: GeneralAgendaBuilder.build_xml(subject: title, body: body)
    )
  end

  def import
    MessageDraftsImport.find(metadata["import_id"]) if metadata["import_id"]
  end

  def submittable?
    title.present? && metadata["message_body"].present? && not_yet_submitted?
  end

  def not_yet_submitted?
    metadata["status"] == "created"
  end

  def being_submitted?
    metadata["status"] == "being_submitted"
  end

  def submitted?
    metadata["status"] == "submitted"
  end

  def original_message
    Message.find(metadata["original_message_id"])
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
    elsif forms.count != 1
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
