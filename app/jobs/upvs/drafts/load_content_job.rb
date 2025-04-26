require 'csv'

class Upvs::Drafts::LoadContentJob < ApplicationJob
  class << self
    delegate :uuid, to: SecureRandom
  end

  def perform(message_draft, message_draft_path)
    ActiveRecord::Base.transaction do
      Dir.each_child(message_draft_path) do |subdirectory_name|
        case subdirectory_name
        when "podpisane"
          load_message_draft_objects(message_draft, File.join(message_draft_path, subdirectory_name), signed: true, to_be_signed: false)
        when "podpisat", "podpisovat"
          load_message_draft_objects(message_draft, File.join(message_draft_path, subdirectory_name), signed: false, to_be_signed: true)
        when "nepodpisat", "nepodpisovat"
          load_message_draft_objects(message_draft, File.join(message_draft_path, subdirectory_name), signed: false, to_be_signed: false)
        end
      end
    end

    save_form_visualisation(message_draft)
  rescue
    message_draft.metadata["status"] = "invalid"
    message_draft.save
  end

  private

  def load_message_draft_objects(message_draft, objects_path, signed:, to_be_signed:)
    Dir.foreach(objects_path) do |file_name|
      next if file_name == '.' or file_name == '..'

      is_form = form?(message_draft, file_name)
      tags = signed ? [message_draft.thread.box.tenant.signed_externally_tag!] : []

      message_draft_object = MessageObject.create(
        name: file_name,
        mimetype: Utils.file_mimetype_by_name(entry_name: file_name, is_form: is_form),
        object_type: is_form ? "FORM" : "ATTACHMENT",
        is_signed: signed,
        message: message_draft,
        visualizable: is_form ? false : nil,
        tags: tags
      )

      if to_be_signed
        message_draft_object.message.tenant.signer_group.signature_requested_from_tag&.assign_to_message_object(message_draft_object)
        message_draft_object.message.tenant.signer_group.signature_requested_from_tag&.assign_to_thread(message_draft_object.message.thread)
      end

      MessageObjectDatum.create(
        message_object: message_draft_object,
        blob: File.read(File.join(objects_path, file_name))
      )
    end

    EventBus.publish_message_created_event(message_draft)
  end

  def form?(message_draft, file_name)
    file_base_name = File.basename(file_name, ".*")

    # Form file must have the same name as subfolder
    file_base_name == message_draft.metadata["import_subfolder"]
  end
  
  def save_form_visualisation(message_draft)

    if message_draft.created_from_template?
      message_draft.metadata["message_body"] = Upvs::FormBuilder.parse_general_agenda_text(message_draft.form_object.content)
      message_draft.save!
    end
  end

  delegate :uuid, to: self
end
