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

  scope :in_submission_process, -> { where("metadata ->> 'status' IN ('being_submitted', 'submitted')") }
  scope :not_in_submission_process, -> { where("metadata ->> 'status' NOT IN ('being_submitted', 'submitted')") }

  validate :validate_uuid
  validates :title, presence: { message: "Title can't be blank" }
  validates :delivered_at, presence: true

  after_create do
    add_cascading_tag(thread.box.tenant.draft_tag!)
    add_cascading_tag(author.draft_tag) if author
  end
  after_update_commit ->(message) { EventBus.publish(:message_draft_changed, message) }

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

      self.remove_cascading_tag(self.thread.tenant.submitted_tag)
    elsif self.thread.message_drafts.in_submission_process.none?
      self.remove_cascading_tag(self.thread.tenant.submitted_tag)
    end
  end

  with_options on: :create_from_template do |message_draft|
    message_draft.validates :sender_name, presence: true
    message_draft.validates :recipient_name, presence: true
    message_draft.validate :validate_metadata_with_template
  end

  with_options on: :validate_data do |message_draft|
    message_draft.validate :validate_data
  end

  with_options on: :validate_uuid_uniqueness do |message_draft|
    message_draft.validate :validate_uuid_uniqueness
  end

  def create_message_objects_from_params(objects_params)
    objects_params.each do |object_params|
      message_object = objects.create(object_params.except(:content, :to_be_signed, :tags))

      object_params.fetch(:tags, []).each do |tag_name|
        tag = tenant.user_signature_tags.find_by(name: tag_name)
        tag.assign_to_message_object(message_object)
        tag.assign_to_thread(thread)
      end
      thread.box.tenant.signed_externally_tag!.assign_to_message_object(message_object) if message_object.is_signed

      if object_params[:to_be_signed]
        tenant.signer_group.signature_requested_from_tag&.assign_to_message_object(message_object)
        tenant.signer_group.signature_requested_from_tag&.assign_to_thread(thread)
      end

      MessageObjectDatum.create(
        message_object: message_object,
        blob: Base64.decode64(object_params[:content])
      )
    end

    publish_created_event
  end

  def assign_tags_from_params(tags_params)
    tags_params.each do |tag_name|
      tag = tenant.tags.find_by(name: tag_name)
      add_cascading_tag(tag)
    end
  end

  def update_content(parameters)
    metadata["data"] = parameters.to_h
    save!

    template.build_message_from_template(self)
    reload
  end

  def submit
    raise NotImplementedError
  end

  def draft?
    true
  end

  def collapsible?
    false
  end

  def editable?
    created_from_template? && !form_object&.is_signed? && not_yet_submitted?
  end

  def destroyable?
    true
  end

  def reason_for_readonly
    return :read_only_agenda unless template.present?
    return :submitted if submitted? || being_submitted?
    return :form_signed if form_object.is_signed?
  end

  def created_from_template?
    template.present?
  end

  def submittable?
    form_object&.content&.present? && correctly_created? && valid?(:validate_data) && !any_objects_with_requested_signature?
  end

  def not_submittable_errors
    return [] if submittable?

    errors = []
    errors << 'Vyplňte obsah správy' unless form_object.content.present?
    errors << 'Pred odoslaním podpíšte všetky dokumenty na podpis' if any_objects_with_requested_signature?
    errors << 'Obsah správy nie je validný' if invalid? || !valid?(:validate_data)
    errors << 'Správu bude možné odoslať až po ukončení validácie' if being_validated?

    errors
  end

  def correctly_created?
    metadata["status"] == "created"
  end

  def invalid?
    metadata["status"] == "invalid"
  end

  def not_yet_submitted?
    metadata["status"].in?(%w[created invalid being_validated])
  end

  def being_validated?
    metadata["status"] == "being_validated"
  end

  def being_submitted?
    metadata["status"] == "being_submitted"
  end

  def submitted?
    metadata["status"] == "submitted"
  end

  def submit_failed?
    metadata["status"].in?(%w[submit_fail temporary_submit_fail])
  end

  def created!
    metadata["status"] = "created"
    save!

    publish_created_event(force_thread_event: true)
  end

  def being_submitted!
    remove_cascading_tag(tenant.draft_tag) if thread.message_drafts.not_in_submission_process.excluding(self).reload.none?
    add_cascading_tag(tenant.submitted_tag)

    metadata["status"] = "being_submitted"
    save!
    EventBus.publish(:message_draft_being_submitted, self)
  end

  def submitted!
    metadata["status"] = "submitted"
    save!
    EventBus.publish(:message_draft_submitted, self)
  end

  def attachments_allowed?
    true
  end

  def original_message
    Message.find(metadata["original_message_id"]) if metadata["original_message_id"]
  end

  def template_validation_errors
    template&.message_data_validation_errors(self)
  end

  def remove_form_signature
    return false unless form_object
    return false unless form_object.is_signed?

    form_object.destroy
    reload
    template&.create_form_object(self)
    reload
  end

  private

  def validate_data
    validate_form_object
    validate_objects
    validate_with_message_template
  end

  def validate_uuid
    if uuid
      errors.add(:uuid, "UUID must be in UUID format") unless uuid.match?(Utils::UUID_PATTERN)
    else
      errors.add(:uuid, "UUID can't be blank")
    end
  end

  def validate_uuid_uniqueness
    errors.add(:uuid, "Message with given UUID already exists") if uuid && box.messages.excluding(self).where(uuid: uuid).any?
  end

  def validate_form_object
    return if errors[:metadata].any?

    raise "Missing XSD schema" unless form&.xsd_schema

    return unless form_object&.unsigned_content

    document = form_object.xml_unsigned_content
    form_errors = document.errors

    schema = Nokogiri::XML::Schema(form.xsd_schema)

    form_errors += schema.validate(document)

    errors.add(:base, :invalid_form) if form_errors.any?
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

  def validate_with_message_template
    template&.validate_message(self)
  end

  def validate_metadata_with_template
    errors.add(:metadata, :no_template) unless metadata&.dig("template_id").present?
  end

  class InvalidSenderError < RuntimeError
  end
end
