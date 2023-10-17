require 'csv'

class Drafts::LoadContentJob < ApplicationJob
  class << self
    delegate :uuid, to: SecureRandom
  end

  def perform(message_draft, message_draft_path)
    ActiveRecord::Base.transaction do
      Dir.each_child(message_draft_path) do |subdirectory_name|
        case subdirectory_name
        when "podpisane"
          load_message_draft_objects(message_draft, File.join(message_draft_path, subdirectory_name), signed: true, to_be_signed: false)
        when "podpisat"
          load_message_draft_objects(message_draft, File.join(message_draft_path, subdirectory_name), signed: false, to_be_signed: true)
        when "nepodpisovat"
          load_message_draft_objects(message_draft, File.join(message_draft_path, subdirectory_name), signed: false, to_be_signed: false)
        end
      end
    end

    save_form_visualisation(message_draft)
  rescue Exception
    message_draft.metadata["status"] = "invalid"
    message_draft.save
  end

  private

  def load_message_draft_objects(message_draft, objects_path, signed:, to_be_signed:)
    Dir.foreach(objects_path) do |file_name|
      next if file_name == '.' or file_name == '..'

      is_form = form?(message_draft, file_name)

      message_draft_object = MessageObject.create(
        name: file_name,
        mimetype: Utils.file_mime_type_by_name(entry_name: file_name, is_form: is_form),
        object_type: is_form ? "FORM" : "ATTACHMENT",
        is_signed: signed,
        to_be_signed: to_be_signed,
        message: message_draft,
        visualizable: is_form ? false : nil
      )

      MessageObjectDatum.create(
        message_object: message_draft_object,
        blob: File.read(File.join(objects_path, file_name))
      )
    end
  end

  def form?(message_draft, file_name)
    file_base_name = File.basename(file_name, ".*")

    # Form file must have the same name as subfolder
    file_base_name == message_draft.metadata["import_subfolder"]
  end
  
  def save_form_visualisation(message_draft)
    upvs_form_template = Upvs::FormTemplate.find_by(identifier: message_draft.metadata["posp_id"], version: message_draft.metadata["posp_version"])
    upvs_form_template_xslt_html = upvs_form_template&.xslt_html

    return unless upvs_form_template_xslt_html

    xslt_template = Nokogiri::XSLT(upvs_form_template_xslt_html)

    if message_draft.form.is_signed?
      # TODO add unsigned_content method which calls UPVS OdpodpisanieDat endpoint and uncomment
      # message_draft.update(
      #   html_visualization: xslt_template.transform(Nokogiri::XML(message_draft.form.unsigned_content)).to_s.gsub('"', '\'')
      # )
      #
      # message_draft.form.update(
      #   visualizable: true
      # )
    else
      message_draft.update(
        html_visualization: xslt_template.transform(Nokogiri::XML(message_draft.form.content)).to_s.gsub('"', '\'')
      )

      if message_draft.custom_visualization?
        message_draft.metadata["message_body"] = Upvs::FormBuilder.parse_general_agenda_text(message_draft.form.content)
        message_draft.save!
      end

      message_draft.form.update(
        visualizable: true
      )
    end
  end

  delegate :uuid, to: self
end
