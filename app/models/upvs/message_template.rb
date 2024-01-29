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

  validate :validate_allow_rules_presence

  def recipients
    Upvs::ServiceWithFormAllowRule.all_institutions_with_template_support(self)
  end

  def create_message(message, author:, box:, recipient_name:, recipient_uri:)
    message.update(
      uuid: SecureRandom.uuid,
      delivered_at: Time.current,
      read: true,
      sender_name: box&.name,
      recipient_name: recipient_name,
      replyable: false,
      outbox: true,
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

    message.thread = box&.message_threads&.find_or_create_by_merge_uuid!(
      box: box,
      merge_uuid: message.metadata['correlation_id'],
      title: self.name,
      delivered_at: message.delivered_at
    )

    message.save

    if message.valid?(:create_from_template)
      message.add_cascading_tag(author.draft_tag)

      create_form_object(message)
    end
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
      outbox: true,
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

    message.add_cascading_tag(author.draft_tag)

    create_form_object(message)
  end

  def build_message_from_template(message)
    template_items = MessageTemplateParser.parse_template_placeholders(self)
    filled_content = self.content.dup

    template_items.each do |template_item|
      value = message.metadata['data'][template_item[:name]]
      value = "#{value}:00" if value && template_item[:type] == 'datetime_local_field'
      filled_content.gsub!(template_item[:placeholder], value.to_s)
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

    return if message.errors[:metadata].any?

    raise "Disallowed form: #{self.name}" unless Upvs::ServiceWithFormAllowRule.form_services(self).any?

    xsd_schema = upvs_form&.xsd_schema

    raise "Missing XSD schema: #{self.name}" unless xsd_schema

    return if message.form.is_signed?

    schema = Nokogiri::XML::Schema(xsd_schema)
    document = Nokogiri::XML(message.form.content)
    errors = schema.validate(document)

    message.errors.add(:base, :invalid_form) if errors.any?
  end

  def create_form_object(message)
    message.objects.create!(
      name: "form.xml",
      mimetype: "application/x-eform-xml",
      object_type: "FORM",
      is_signed: false
    )
    build_message_from_template(message)
  end

  private

  def upvs_form
    Upvs::Form.find_by(
      identifier: metadata['posp_id'],
      version: metadata['posp_version'],
      message_type: metadata['message_type']
    )
  end

  def form_services
    Upvs::ServiceWithFormAllowRule.where("schema_url LIKE ?", "%#{metadata['posp_id']/metadata['posp_version']}")
  end

  def validate_allow_rules_presence
    errors.add(:base, "Disallowed form") unless Upvs::ServiceWithFormAllowRule.form_services(self).any?
  end
end
