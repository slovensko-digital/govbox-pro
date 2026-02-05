# == Schema Information
#
# Table name: messages
#
#  id                 :bigint           not null, primary key
#  collapsed          :boolean          default(FALSE), not null
#  delivered_at       :datetime         not null
#  export_metadata    :jsonb            not null
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
class Message < ApplicationRecord
  include MessageHelper
  include MessageExportOperations

  belongs_to :thread, class_name: 'MessageThread', foreign_key: :message_thread_id, inverse_of: :messages
  belongs_to :author, class_name: 'User', foreign_key: :author_id, optional: true
  has_many :message_relations, dependent: :destroy
  has_many :message_relations_as_related_message, class_name: 'MessageRelation', foreign_key: :related_message_id, dependent: :destroy
  has_many :related_messages, through: :message_relations
  has_many :messages_tags, dependent: :destroy
  has_many :tags, through: :messages_tags
  has_many :objects, class_name: 'MessageObject', dependent: :destroy, inverse_of: :message
  has_many :attachments, -> { where(object_type: "ATTACHMENT") }, class_name: 'MessageObject', inverse_of: :message
  # used for joins only
  has_many :message_threads_tags, primary_key: :message_thread_id, foreign_key: :message_thread_id

  store_accessor :export_metadata, :box_name, prefix: true

  delegate :tenant, to: :thread
  delegate :box, to: :thread

  scope :not_drafts, -> { where(type: [nil, 'Message']) }
  scope :outbox, -> { where(outbox: true) }
  scope :inbox, -> { not_drafts.where.not(outbox: true) }

  after_update_commit ->(message) { EventBus.publish(:message_changed, message) }
  after_destroy_commit ->(message) { EventBus.publish(:message_destroyed, message) }

  def automation_rules_for_event(event)
    tenant.automation_rules.where(trigger_event: event)
  end

  def add_cascading_tag(tag)
    messages_tags.find_or_create_by!(tag: tag)
    thread.message_threads_tags.find_or_create_by!(tag: tag)
  end

  def remove_cascading_tag(tag)
    messages_tags.find_by(tag: tag)&.destroy
    thread.message_threads_tags.find_by(tag: tag)&.destroy unless thread.messages.reload.any? {|m| m.tags.include?(tag) }
  end

  def prepare_and_validate_message
    #   noop
  end

  def draft?
    false
  end

  def form_object
    objects.select { |o| o.form? }&.first
  end

  def destroyable?
    false
  end

  def submittable?
    false
  end

  def collapsible?
    true
  end

  def replyable_in_thread?
    thread.messages.where(replyable: true).order(:delivered_at).last == self
  end

  def visualizable_body?
    html_visualization.present? || (form_object && form_object.nested_message_objects.count > 1)
  end

  def can_be_authorized?
    metadata["delivery_notification"] && !metadata["authorized"] && Time.parse(metadata.dig("delivery_notification", "delivery_period_end_at")) > Time.now
  end

  def authorized?
    metadata["delivery_notification"] && metadata["authorized"] == true
  end

  def any_objects_with_requested_signature?
    MessageObjectsTag.where(message_object: objects, tag: tenant.tags.signature_requesting).exists?
  end

  # TODO remove UPVS, FS stuff from core domain
  def form
    if metadata['fs_form_id'].present?
      ::Fs::Form.find(metadata['fs_form_id'])
    elsif all_metadata['posp_id'].present? && all_metadata['posp_version'].present?
      ::Upvs::Form.find_by(
        identifier: all_metadata['posp_id'],
        version: all_metadata['posp_version']
      )
    else
      # TODO forms without posp_id, posp_versions
      ::Upvs::Form.find_by(
        identifier: all_metadata['message_type']
      )
    end
  end

  def message_type
    metadata['fs_message_type'] || metadata['edesk_class']
  end

  def update_html_visualization
    self.update(
      html_visualization: build_html_visualization
    )

    form_object&.update(
      visualizable: html_visualization.present?
    )
  end

  def build_html_visualization
    return self.html_visualization if self.html_visualization.present?

    return unless form&.xslt_html
    return unless form_object&.unsigned_content

    template = Nokogiri::XSLT(form.xslt_html)
    template.transform(form_object.xml_unsigned_content)
  end

  def copy_tags_from_draft(message_draft)
    message_draft.objects.map do |message_draft_object|
      message_object = objects.find_by(uuid: message_draft_object.uuid)
      message_draft_object.tags.signed.each { |tag| message_object.assign_tag(tag) }
    end

    (message_draft.tags.simple + message_draft.tags.author + message_draft.tags.signed).each { |tag| assign_tag(tag) }
  end

  def export_summary
    metadata_whitelist = %w[fs_message_id fs_sent_message_id fs_status fs_submission_status fs_submitting_subject fs_message_type fs_submission_type_name fs_submission_created_at fs_period fs_dismissal_reason dic correlation_id reference_id edesk_class sender_uri]

    {
      message_thread_id: message_thread_id,
      title: title,
      box: box.official_name,
      delivered_at: delivered_at,
      tags: thread.tags.map(&:name),
      outbox: outbox,
    }.merge!(metadata.slice(*metadata_whitelist))
  end

  def assign_tag(tag)
    messages_tags.find_or_create_by!(tag: tag)
  end

  def all_metadata
    metadata.merge(template&.metadata || {})
  end

  def template
    MessageTemplate.find(metadata.dig("template_id")) if metadata.dig("template_id")
  end
end
