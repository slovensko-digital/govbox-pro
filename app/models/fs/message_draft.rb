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

  def self.create_with_fs_form(fs_form, box:, form_file: nil)
    message = ::Fs::MessageDraft.create(
      uuid: SecureRandom.uuid,
      title: fs_form.name,
      sender_name: box.name,
      recipient_name: 'Finančná správa',
      outbox: true,
      replyable: false,
      delivered_at: Time.now,
      metadata: {
        'fs_form_id': fs_form.id
      }
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
      mimetype: form_file.content_type,
      is_signed: false,
    )
    MessageObjectDatum.create(
      message_object: form_object,
      blob: form_file.read.force_encoding("UTF-8")
    )

    message
  end

  def submit
    raise NotImplementedError
  end

  def form
    Fs::Form.find(metadata['fs_form_id'])
  end
end