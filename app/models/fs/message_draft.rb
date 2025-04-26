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
class Fs::MessageDraft < MessageDraft
  def self.policy_class
    MessageDraftPolicy
  end

  def self.create_and_validate_with_fs_form(form_files: [], author:, fs_client: FsEnvironment.fs_client)
    messages = []
    errors = []

    form_files.each do |form_file|
      form_content = form_file.read.force_encoding("UTF-8")
      form_information = fs_client.api.parse_form(form_content)
      dic = form_information&.dig('subject')&.strip
      fs_form_identifier = form_information&.dig('form_identifier')

      box = author.tenant.boxes.with_enabled_message_drafts_import.find_by("settings ->> 'dic' = ?", dic)

      if box.nil?
        errors << form_file.original_filename
        next
      end

      fs_form = Fs::Form.find_by(identifier: fs_form_identifier)

      klass = fs_form.nil? ? Fs::InvalidMessageDraft : Fs::MessageDraft
      message = klass.create(
        uuid: SecureRandom.uuid,
        title: fs_form&.name || "Neznámy formulár - #{form_file.original_filename}",
        sender_name: box.name,
        recipient_name: 'Finančná správa',
        outbox: true,
        replyable: false,
        delivered_at: Time.now,
        metadata: {
          'status': fs_form.nil? ? 'invalid' : 'being_loaded',
          'fs_form_id': fs_form&.id,
          'correlation_id': SecureRandom.uuid
        },
        author: author
      )

      message.thread = box.message_threads&.find_or_build_by_merge_uuid(
        box: box,
        merge_uuid: SecureRandom.uuid,
        title: message.title,
        delivered_at: message.delivered_at
      )

      message.save

      if message.type == 'Fs::InvalidMessageDraft'
        messages << message
        next
      end

      form_object = message.objects.create(
        object_type: 'FORM',
        name: form_file.original_filename,
        mimetype: form_file.content_type
      )
      form_object.update(is_signed: form_object.asice?)
      message.thread.box.tenant.signed_externally_tag!.assign_to_message_object(form_object) if form_object.is_signed?

      if fs_form.signature_required && !form_object.is_signed?
        message.thread.box.tenant.signer_group.signature_requested_from_tag&.assign_to_message_object(form_object)
        message.thread.box.tenant.signer_group.signature_requested_from_tag&.assign_to_thread(message.thread)
      end

      MessageObjectDatum.create(
        message_object: form_object,
        blob: form_content
      )

      messages << message

      Fs::ValidateMessageDraftJob.perform_later(message)

      EventBus.publish(:message_thread_created, message.thread)
      EventBus.publish(:message_created, message)
    end

    [messages, errors]
  end

  def submit
    Fs::SubmitMessageDraftAction.run(self)
  end

  def attachments_allowed?
    false
  end

  def build_html_visualization
    Fs::MessageHelper.build_html_visualization_from_form(self)
  end

  def form
    Fs::Form.find(metadata['fs_form_id'])
  end

  private

  def validate_data
    validate_uuid_uniqueness
    validate_metadata
    validate_form_object
  end

  def validate_metadata
    errors.add(:metadata, 'No form ID') unless metadata&.dig('fs_form_id')
  end
end
