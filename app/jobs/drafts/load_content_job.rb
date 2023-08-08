require 'csv'

class Drafts::LoadContentJob < ApplicationJob
  class << self
    delegate :uuid, to: SecureRandom
  end

  def perform(message_draft, message_draft_path)
    Dir.each_child(message_draft_path) do |subdirectory_name|
      case subdirectory_name
      when "podpisane"
        load_draft_message_drafts(message_draft, File.join(message_draft_path, subdirectory_name), signed: true, to_be_signed: false)
      when "podpisat"
        load_draft_message_drafts(message_draft, File.join(message_draft_path, subdirectory_name), signed: false, to_be_signed: true)
      when "nepodpisovat"
        load_draft_message_drafts(message_draft, File.join(message_draft_path, subdirectory_name), signed: false, to_be_signed: false)
      end
    end
  end

  private

  def load_draft_message_drafts(message_draft, objects_path, signed:, to_be_signed:)
    Dir.foreach(objects_path) do |file_name|
      next if file_name == '.' or file_name == '..'

      is_form = form?(message_draft, file_name)

      draft_message_draft = MessageObject.create(
        name: file_name,
        mimetype: Utils.detect_mime_type(entry_name: file_name, is_form: is_form),
        object_type: is_form ? "FORM" : "ATTACHMENT",
        is_signed: signed,
        to_be_signed: to_be_signed,
        message: message_draft
      )

      MessageObjectDatum.create(
        message_object: draft_message_draft,
        blob: File.read(File.join(objects_path, file_name))
      )

      draft_message_draft.save!
    end
  end

  def form?(message_draft, file_name)
    file_base_name = File.basename(file_name, ".*")

    # Form file must have the same name as subfolder
    file_base_name == message_draft.metadata["import_subfolder"]
  end

  delegate :uuid, to: self
end
