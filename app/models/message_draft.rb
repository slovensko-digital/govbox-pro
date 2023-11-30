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
  belongs_to :import, class_name: 'MessageDraftsImport', foreign_key: :import_id, optional: true

  after_create do
    drafts_tag = self.thread.box.tenant.tags.find_by(system_name: Tag::DRAFT_SYSTEM_NAME)
    self.add_cascading_tag(drafts_tag)
  end

  after_destroy do
    EventBus.publish(:message_draft_destroyed, self)
    # TODO has to use `reload` because of `inverse_of` messages are in memory and deleting already deleted record fails
    if self.thread.messages.reload.none?
      self.thread.destroy!
    elsif self.thread.message_drafts.reload.none?
      drafts_tag = self.thread.tags.find_by(system_name: Tag::DRAFT_SYSTEM_NAME)
      self.remove_cascading_tag(drafts_tag)
    end
  end

  with_options on: :validate_data do |message_draft|
    message_draft.validates :uuid, format: { with: Utils::UUID_PATTERN }, allow_blank: false
    message_draft.validate :validate_metadata
    message_draft.validate :validate_form
    message_draft.validate :validate_objects
    message_draft.validate :validate_with_message_template
  end

  def update_content(parameters)
    metadata["data"] = parameters.to_h
    self.save!

    template.build_message_from_template(self)

    self.reload
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

  def custom_visualization?
    template.present?
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
    metadata["status"] == "invalid" || valid?(:validate_data)
  end

  def original_message
    Message.find(metadata["original_message_id"]) if metadata["original_message_id"]
  end

  def template
    MessageTemplate.find(metadata["template_id"]) if metadata["template_id"]
  end

  def template_validation_errors
    template&.message_data_validation_errors(self)
  end

  private

  def validate_with_message_template
    template&.validate_message(self)
  end

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
