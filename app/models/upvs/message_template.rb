# == Schema Information
#
# Table name: message_templates
#
#  id         :bigint           not null, primary key
#  content    :text             not null
#  metadata   :jsonb
#  name       :string           not null
#  system     :boolean          default(FALSE), not null
#  type       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  tenant_id  :bigint
#
class Upvs::MessageTemplate < ::MessageTemplate
  GENERAL_AGENDA_POSP_ID = "App.GeneralAgenda"
  GENERAL_AGENDA_POSP_VERSION = "1.9"
  GENERAL_AGENDA_MESSAGE_TYPE = "App.GeneralAgenda"

  def recipients
    # TODO nacitat z DB allow listu
    [
      ['Test OVM 83136952', 'ico://sk/83136952'],
      ['Test OVM 83369721', 'ico://sk/83369721'],
      ['Test OVM 83369722', 'ico://sk/83369722'],
      ['Test OVM 83369723', 'ico://sk/83369723']
    ]
  end

  def create_message(message, author:, box:, recipient_name:, recipient_uri:)
    message.update(
      uuid: SecureRandom.uuid,
      delivered_at: Time.current,
      read: true,
      sender_name: box&.name,
      recipient_name: recipient_name,
      replyable: false,
      title: self.name,
      author: author
    )

    data = MessageTemplateParser.parse_template_placeholders(self).each_with_object({}) do |item, out|
      out[item[:name]] = item[:default_value]
    end

    message.metadata = {
      template_id: self.id,
      data: data,
      recipient_uri: recipient_uri,
      correlation_id: SecureRandom.uuid,
      status: 'created'
    }

    message.thread = box.message_threads.find_or_create_by_merge_uuid!(
      box: box,
      merge_uuid: message.metadata['correlation_id'],
      title: self.name,
      delivered_at: message.delivered_at
    )

    message.save!

    create_form_object(message)
  end

  def create_message_reply(message, original_message:, author:)
    message_title = "Odpoveď: #{original_message.title}"

    message.update(
      uuid: SecureRandom.uuid,
      delivered_at: Time.current,
      read: true,
      sender_name: original_message.recipient_name,
      recipient_name: original_message.sender_name,
      replyable: false,
      title: message_title,
      author: author
    )
    message.metadata = {
      template_id: self.id,
      data: {
        Predmet: message_title
      },
      recipient_uri: original_message.metadata["sender_uri"],
      correlation_id: original_message.metadata["correlation_id"],
      reference_id: original_message.uuid,
      original_message_id: original_message.id,
      status: 'created'
    }
    message.thread = original_message.thread
    message.save!

    create_form_object(message)
  end

  def build_message_from_template(message)
    template_items = MessageTemplateParser.parse_template_placeholders(self)
    filled_content = self.content

    template_items.each do |template_item|
      filled_content.gsub!(template_item[:placeholder], message.metadata['data'][template_item[:name]])
    end

    if message.form.message_object_datum
      message.form.message_object_datum.update(
        blob: filled_content
      )
    else
      message.form.message_object_datum = MessageObjectDatum.create(
        message_object: message.form,
        blob: filled_content
      )
    end
  end

  def validate_message(message)
    template_items = MessageTemplateParser.parse_template_placeholders(self)
    required_template_items = template_items.select{ |item| item[:required] }.pluck(:name)

    required_template_items.each do |template_item|
      message.errors.add(:metadata, :blank, attribute: template_item) unless message.metadata["data"][template_item].present?
    end
  end

  def create_form_object(message)
    message.objects.create!(
      name: "form.xml",
      mimetype: "application/x-eform-xml",
      object_type: "FORM",
      is_signed: false
    )
  end
end
