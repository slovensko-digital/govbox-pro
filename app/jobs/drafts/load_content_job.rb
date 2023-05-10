require 'csv'

class Drafts::LoadContentJob < ApplicationJob
  class << self
    delegate :uuid, to: SecureRandom
  end

  def perform(draft, draft_path)
    Dir.each_child(draft_path) do |subdirectory_name|
      case subdirectory_name
      when "podpisane"
        load_draft_objects(draft, File.join(draft_path, subdirectory_name), signed: true, to_be_signed: false)
      when "podpisat"
        load_draft_objects(draft, File.join(draft_path, subdirectory_name), signed: false, to_be_signed: true)
      when "nepodpisovat"
        load_draft_objects(draft, File.join(draft_path, subdirectory_name), signed: false, to_be_signed: false)
      end
    end
  end

  private

  def load_draft_objects(draft, objects_path, signed:, to_be_signed:)
    Dir.foreach(objects_path) do |filename|
      next if filename == '.' or filename == '..'

      draft_object = Drafts::Object.create(
        draft_id: draft.id,
        uuid: uuid,
        name: filename,
        form: form?(draft, filename),
        signed: signed,
        to_be_signed: to_be_signed
      )

      File.open(File.join(objects_path, filename)) do |io|
        draft_object.content.attach(io: io, filename: filename)
      end

      draft_object.save!
    end
  end

  def form?(draft, filename)
    file_basename = File.basename(filename, ".*")

    # Form file must have the same name as subfolder
    file_basename == draft.import_subfolder
  end

  delegate :uuid, to: self
end
