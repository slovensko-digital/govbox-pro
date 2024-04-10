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
class Upvs::MessageDraft < MessageDraft
  validate :validate_correlation_id

  def self.load_and_validate(message_params, box:)
    message_params = message_params.permit(
      :type,
      :uuid,
      :title,
      metadata: [
        :correlation_id,
        :reference_id,
        :sender_uri,
        :recipient_uri,
        :sender_business_reference,
        :recipient_business_reference,
        :posp_id,
        :posp_version,
        :message_type,
        :sktalk_class
      ]
    )

    message = ::Message.create(message_params.except(:objects, :tags).merge(
        {
          sender_name: box.name,
          # recipient_name: TODO search name in UPVS dataset,
          outbox: true,
          replyable: false,
          delivered_at: Time.now
        }
      )
    )

    message.thread = box.message_threads&.find_or_build_by_merge_uuid(
      box: box,
      merge_uuid: message.metadata['correlation_id'],
      title: message.title,
      delivered_at: message.delivered_at
    )

    return message unless message.valid?

    message.save
    message
  end

  private

  def validate_uuid
    if uuid
      errors.add(:metadata, 'Message ID must be in UUID format') unless uuid.match?(Utils::UUID_PATTERN)
    else
      errors.add(:metadata, "Message ID can't be blank")
    end
  end

  def validate_correlation_id
    if all_metadata&.dig("correlation_id")
      errors.add(:metadata, "Correlation ID must be UUID") unless all_metadata.dig("correlation_id").match?(Utils::UUID_PATTERN)
    else
      errors.add(:metadata, "Correlation ID can't be blank")
    end
  end
end
