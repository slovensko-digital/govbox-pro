# == Schema Information
#
# Table name: messages
#
#  id                 :bigint           not null, primary key
#  collapsed          :boolean          default(FALSE), not null
#  delivered_at       :datetime         not null
#  html_visualization :text
#  metadata           :json
#  outbox             :boolean          default(FALSE), not null
#  read               :boolean          default(FALSE), not null
#  recipient_name     :string
#  replyable          :boolean          default(TRUE), not null
#  sender_name        :string
#  title              :string
#  type               :string
#  uuid               :uuid             not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  author_id          :bigint
#  import_id          :bigint
#  message_thread_id  :bigint           not null
#
class MessageDraft < Message
  belongs_to :import, class_name: 'MessageDraftsImport', optional: true

  after_create do
    add_cascading_tag(thread.box.tenant.draft_tag!)
  end

  after_destroy do
    EventBus.publish(:message_draft_destroyed, self)
    # TODO: has to use `reload` because of `inverse_of` messages are in memory and deleting already deleted record fails
    if thread.messages.reload.none?
      thread.destroy!
    elsif thread.message_drafts.reload.none?
      drafts_tag = thread.tags.find_by(type: DraftTag.to_s)
      thread.tags.delete(drafts_tag)
    end
  end

  GENERAL_AGENDA_POSP_ID = "App.GeneralAgenda"
  GENERAL_AGENDA_POSP_VERSION = "1.9"
  GENERAL_AGENDA_MESSAGE_TYPE = "App.GeneralAgenda"

  with_options on: :validate_data do
    validates :uuid, format: { with: Utils::UUID_PATTERN }, allow_blank: false
    validate :validate_metadata
    validate :validate_form
    validate :validate_objects
  end

  def self.create_message_reply(original_message:, author:)
    message_draft = original_message.thread.message_drafts.create!(
      uuid: SecureRandom.uuid,
      sender_name: original_message.recipient_name,
      recipient_name: original_message.sender_name,
      title: "Odpoveď: #{original_message.title}",
      read: true,
      delivered_at: Time.now,
      author: author,
      outbox: true,
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
    message_draft.create_form_object

    message_draft
  end

  def update_content(title:, body:)
    self.title = title
    metadata["message_body"] = body
    save!
    return unless title.present? && body.present?

    update_form_object
    reload
  end

  def draft?
    true
  end

  def collapsible?
    false
  end

  def editable?
    metadata["posp_id"] == GENERAL_AGENDA_POSP_ID && !form&.is_signed? && not_yet_submitted?
  end

  def reason_for_readonly
    return :read_only_agenda unless metadata["posp_id"] == GENERAL_AGENDA_POSP_ID
    return :form_submitted if submitted? || being_submitted?
    return :form_signed if form.is_signed?
  end

  def custom_visualization?
    metadata["posp_id"] == GENERAL_AGENDA_POSP_ID
  end

  def submittable?
    form.content.present? && objects.to_be_signed.all? { |o| o.is_signed? } && !invalid? && not_yet_submitted?
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
    EventBus.publish(:message_draft_being_submitted, self)
  end

  def submitted!
    metadata["status"] = "submitted"
    save!
    EventBus.publish(:message_draft_submitted, self)
  end

  def invalid?
    metadata["status"] == "invalid"
  end

  def original_message
    Message.find(metadata["original_message_id"]) if metadata["original_message_id"]
  end

  def remove_form_signature
    return false unless form
    return false unless form.is_signed?

    form.destroy
    create_form_object
    reload
    update_form_object
  end

  def create_form_object
    # TODO: clean the domain (no UPVS stuff)
    objects.create!(
      name: "form.xml",
      mimetype: "application/x-eform-xml",
      object_type: "FORM",
      is_signed: false
    )
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

  def update_form_object
    # TODO: clean the domain (no UPVS stuff)
    if form.message_object_datum
      form.message_object_datum.update(
        blob: Upvs::FormBuilder.build_general_agenda_xml(subject: title, body: metadata["message_body"])
      )
    else
      form.message_object_datum = MessageObjectDatum.create(
        message_object: form,
        blob: Upvs::FormBuilder.build_general_agenda_xml(subject: title, body: metadata["message_body"])
      )
    end
  end
end
