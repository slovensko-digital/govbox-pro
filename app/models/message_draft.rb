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

  validate :validate_uuid
  validates :title, presence: { message: "Title can't be blank" }
  validates :delivered_at, presence: true

  after_create do
    add_cascading_tag(thread.box.tenant.draft_tag!)
  end

  after_destroy do
    EventBus.publish(:message_draft_destroyed, self)
    # TODO has to use `reload` because of `inverse_of` messages are in memory and deleting already deleted record fails
    if self.thread.messages.reload.none?
      self.thread.destroy!
    elsif self.thread.message_drafts.reload.none?
      drafts_tags = self.thread.tags.where(type: DraftTag.to_s)
      drafts_tags.each do |drafts_tag|
        self.remove_cascading_tag(drafts_tag)
      end
    end
  end

  with_options on: :create_from_template do |message_draft|
    message_draft.validates :sender_name, presence: true
    message_draft.validates :recipient_name, presence: true
    message_draft.validate :validate_metadata_with_template
    message_draft.validate :validate_form
  end

  with_options on: :validate_data do |message_draft|
    message_draft.validate :validate_metadata
    message_draft.validate :validate_form
    message_draft.validate :validate_objects
    message_draft.validate :validate_with_message_template
  end

  def update_content(parameters)
    metadata["data"] = parameters.to_h
    save!

    template.build_message_from_template(self)
    reload
  end

  def draft?
    true
  end

  def collapsible?
    false
  end

  def editable?
    custom_visualization? && !form&.is_signed? && not_yet_submitted?
  end

  def reason_for_readonly
    return :read_only_agenda unless template.present?
    return :form_submitted if submitted? || being_submitted?
    return :form_signed if form.is_signed?
  end

  def custom_visualization?
    template.present?
  end

  def submittable?
    form.content.present? && objects.to_be_signed.all? { |o| o.is_signed? } && !invalid? && not_yet_submitted?
  end

  def correctly_created?
    metadata["status"] == "created"
  end

  def not_yet_submitted?
    metadata["status"] == "created" || metadata["status"] == "invalid"
  end

  def being_submitted?
    metadata["status"] == "being_submitted"
  end

  def submitted?
    metadata["status"] == "submitted"
  end

  def submit_failed?
    metadata["status"] == "submit_fail"
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
    metadata["status"] == "invalid" || !valid?(:validate_data)
  end

  def original_message
    Message.find(metadata["original_message_id"]) if metadata["original_message_id"]
  end

  def template_validation_errors
    template&.message_data_validation_errors(self)
  end

  def remove_form_signature
    return false unless form
    return false unless form.is_signed?

    form.destroy
    reload
    template&.create_form_object(self)
    reload
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

  # TODO remove UPVS stuff from core domain
  def validate_form
    return if errors[:metadata].any?

    unless ::Upvs::ServiceWithFormAllowRule.form_services(all_metadata).where(institution_uri: metadata['recipient_uri']).any?
      errors.add(:base, :disallowed_form_for_recipient)
      return
    end

    raise "Missing XSD schema" unless upvs_form&.xsd_schema

    form_content = form&.unsigned_content

    if form_content
      document = Nokogiri::XML(form_content)
      form_errors = document.errors

      document = Nokogiri::XML(document.children.first.children.first.children.first.to_xml) if document.children.first.name == 'XMLDataContainer'

      schema = Nokogiri::XML::Schema(upvs_form&.xsd_schema)
      form_errors += schema.validate(document)

      errors.add(:base, :invalid_form) if form_errors.any?
    end
  end

  private

  def validate_uuid
    if uuid
      errors.add(:metadata, "UUID must be in UUID format") unless uuid.match?(Utils::UUID_PATTERN)
    else
      errors.add(:metadata, "UUID can't be blank")
    end
  end

  def validate_objects
    if objects.size == 0
      errors.add(:objects, "Message contains no objects")
      return
    end

    objects.each do |object|
      object.valid?(:validate_data)
      errors.merge!(object.errors)
    end

    forms = objects.select { |o| o.form? }
    errors.add(:objects, "Message has to contain exactly one form object") if forms.size != 1
  end

  def validate_metadata
    errors.add(:metadata, "No recipient URI") unless all_metadata&.dig("recipient_uri")
    errors.add(:metadata, "No posp ID") unless all_metadata&.dig("posp_id")
    errors.add(:metadata, "No posp version") unless all_metadata&.dig("posp_version")
    errors.add(:metadata, "No message type") unless all_metadata&.dig("message_type")

    errors.add(:metadata, "Reference ID must be UUID") if all_metadata&.dig("reference_id") && !all_metadata&.dig("reference_id")&.match?(Utils::UUID_PATTERN)
  end

  def validate_with_message_template
    template&.validate_message(self)
  end

  def validate_metadata_with_template
    errors.add(:metadata, :no_template) unless metadata&.dig("template_id").present?
  end
end
