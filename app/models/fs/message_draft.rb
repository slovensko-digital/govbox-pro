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
class Fs::MessageDraft < MessageDraft
  def self.policy_class
    MessageDraftPolicy
  end

  def self.create_and_validate_with_fs_form(form_files: [], author:)
    messages = []
    failed_files = []

    form_files.each do |form_file|
      form_content = form_file.read.force_encoding("UTF-8")

      box, fs_form, period = get_parsed_box_and_form_from_content(form_content, tenant: author.tenant)

      if box.nil?
        failed_files << form_file
        next
      end

      klass = fs_form ? Fs::MessageDraft : Fs::InvalidMessageDraft
      message = klass.create(
        uuid: SecureRandom.uuid,
        title: fs_form&.name || "Neznámy formulár - #{form_file.original_filename}",
        sender_name: box.name,
        recipient_name: 'Finančná správa',
        outbox: true,
        replyable: false,
        delivered_at: Time.now,
        metadata: {
          'status': fs_form ? 'being_loaded' : 'invalid',
          'fs_form_id': fs_form&.id,
          'fs_form_slug': fs_form&.slug,
          'fs_form_subtype_name': fs_form&.subtype_name,
          'dic': box.settings['dic'],
          'period': period,
          'correlation_id': SecureRandom.uuid
        },
        author: author
      )

      message.thread = box.message_threads&.find_or_build_by_merge_uuid(
        box: box,
        merge_uuid: SecureRandom.uuid,
        title: message.title,
        delivered_at: message.delivered_at,
        metadata: {
          period: period,
          fs_form_id: fs_form&.id
        }
      )

      message.save
      messages << message

      next if message.invalid?

      form_object = message.objects.create(
        object_type: 'FORM',
        name: form_file.original_filename,
        mimetype: form_file.content_type
      )
      form_object.update(is_signed: form_object.asice?)
      message.thread.box.tenant.signed_externally_tag!.assign_to_message_object(form_object) if form_object.is_signed?

      message.thread.assign_tag(message.thread.box.tenant.simple_tags.find_or_create_by!(name: period)) if period

      MessageObjectDatum.create(
        message_object: form_object,
        blob: form_content
      )

      EventBus.publish(:message_thread_with_message_created, message)
    end

    [messages, failed_files]
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
    box, fs_form, period = get_parsed_box_and_form_from_content(form_content, tenant: tenant)

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
          'fs_form_slug': fs_form.slug,
          'fs_form_subtype_name': fs_form.subtype_name,
          'dic': box.settings['dic'],
          'period': period
        }),
      })
    )

    message.thread = box.message_threads&.find_or_build_by_merge_uuid(
      box: box,
      merge_uuid: message.metadata&.dig('correlation_id'),
      title: message.title,
      delivered_at: message.delivered_at,
      metadata: {
        period: period,
        fs_form_id: fs_form.id
      }
    )

    message
  end

  def self.get_parsed_box_and_form_from_content(form_content, tenant:, fs_client: FsEnvironment.fs_client)
    form_information = fs_client.api.parse_form(form_content)
    dic = form_information&.dig('subject')&.strip
    fs_form_identifier = form_information&.dig('form_identifier')
    period = form_information&.dig('period')&.dig('pretty')

    box = tenant.boxes.with_enabled_message_drafts_import.find_by("settings ->> 'dic' = ?", dic)
    fs_form = Fs::Form.find_by(identifier: fs_form_identifier)

    return box, fs_form, period
  end

  def find_api_connection_for_submission
    return box.api_connection if box.api_connections.count == 1 && !box.api_connection.owner

    raise "Multiple signatures found. Can't choose API connection" if form_object.tags.where(type: "SignedByTag").count > 1

    signed_by = form_object.tags.where(type: "SignedByTag")&.first&.owner

    return box.api_connections.find_by(owner: signed_by) if signed_by && box.api_connections.find_by(owner: signed_by)

    raise "Signer not allowed to submit the message"
  end

  def assign_tags_from_params(tags_params)
    period = thread.metadata.dig('period')
    thread.assign_tag(thread.box.tenant.simple_tags.find_or_create_by!(name: period)) if period

    super
  end

  def prepare_and_validate_message
    metadata['status'] = 'being_validated'
    metadata[:validation_errors] = {}
    save!

    remove_cascading_tag(tenant.submission_error_tag)

    form_object.tags.where(type: SignatureRequestedFromTag.to_s).each do |tag|
      form_object.unassign_tag(tag)
    end

    thread.tags.where(type: [SignatureRequestedTag.to_s, SignatureRequestedFromTag.to_s]).each do |tag|
      thread.unassign_tag(tag)
    end

    Fs::ValidateMessageDraftJob.set(job_context: :asap).perform_later(self)
  end

  def submit
    Fs::SubmitMessageDraftAction.run(self)
  end

  def attachments_editable?
    tenant.feature_enabled?(:fs_submissions_with_attachments) && not_yet_submitted?
  end

  def build_html_visualization
    Fs::MessageHelper.build_html_visualization_from_form(self)
  end

  def form
    Fs::Form.find_by(id: metadata['fs_form_id'])
  end

  def signable_by_author?
    return false unless author
    return false unless author.signer?
    return true if global_api_connection?
    return true if author_api_connection?
    false
  end

  def signature_target_group
    tenant = thread.box.tenant

    if tenant.signature_request_mode == 'author' && signable_by_author?
      author
    else
      tenant.signer_group
    end
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
    if !tenant.feature_enabled?(:fs_submissions_with_attachments)
      errors.add(:objects, "Message has to contain exactly one object") if objects.size != 1
    else
      super
    end
  end

  def global_api_connection?
    box.api_connections.where(owner: nil).one?
  end

  def author_api_connection?
    box.api_connections.where(owner: author).present?
  end
end
