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

  def self.create_and_validate_with_fs_form(form_files: [], author:)
    messages = []

    form_files.each do |form_file|
      form_content = form_file.read.force_encoding("UTF-8")

      box, fs_form = get_parsed_box_and_form_from_content(form_content, tenant: author.tenant)

      unless box && fs_form
        messages << nil
        next
      end

      message = ::Fs::MessageDraft.create(
        uuid: SecureRandom.uuid,
        title: fs_form.name,
        sender_name: box.name,
        recipient_name: 'Finančná správa',
        outbox: true,
        replyable: false,
        delivered_at: Time.now,
        metadata: {
          'status': 'being_loaded',
          'fs_form_id': fs_form.id,
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

      message.publish_created_event
    end

    messages
  end

  def self.load_from_params(message_params, tenant: nil, box: nil)
    message_params = message_params.permit(
      :type,
      :uuid,
      :title,
      objects: [
        :name,
        :is_signed,
        :to_be_signed,
        :mimetype,
        :object_type,
        :content
      ],
      metadata: [
        :correlation_id
      ]
    )

    b64_form_content = message_params[:objects]&.select{|o| o['object_type'] == 'FORM'}&.first&.dig('content')&.force_encoding("UTF-8")

    raise MissingFormObjectError unless b64_form_content

    form_content = Base64.decode64(b64_form_content)
    box, fs_form = get_parsed_box_and_form_from_content(form_content, tenant: tenant)

    raise InvalidSenderError unless box
    raise UnknownFormError unless fs_form

    message = ::Message.build(message_params.except(:objects, :tags).merge(
      {
        sender_name: box.name,
        recipient_name: 'Finančná správa',
        outbox: true,
        replyable: false,
        delivered_at: Time.now,
        metadata: (message_params['metadata'] || {}).merge({
          'status': 'being_loaded',
          'fs_form_id': fs_form.id,
        }),
      })
    )

    message.thread = box.message_threads&.find_or_build_by_merge_uuid(
      box: box,
      merge_uuid: message.metadata&.dig('correlation_id'),
      title: message.title,
      delivered_at: message.delivered_at
    )

    message
  end

  def self.get_parsed_box_and_form_from_content(form_content, tenant:, fs_client: FsEnvironment.fs_client)
    form_information = fs_client.api.parse_form(form_content)
    dic = form_information&.dig('subject')&.strip
    fs_form_identifier = form_information&.dig('form_identifier')

    box = tenant.boxes.with_enabled_message_drafts_import.find_by("settings ->> 'dic' = ?", dic)
    fs_form = Fs::Form.find_by(identifier: fs_form_identifier)

    return box, fs_form
  end

  def publish_created_event(force_thread_event: false)
    super(force_thread_event: force_thread_event)

    Fs::ValidateMessageDraftJob.perform_later(self)
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
    validate_objects
  end

  def validate_metadata
    errors.add(:metadata, 'No form ID') unless metadata&.dig('fs_form_id')
  end

  def validate_objects
    errors.add(:objects, "Message has to contain exactly one object") if objects.size != 1
  end
end
