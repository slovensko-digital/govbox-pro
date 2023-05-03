class Drafts::ImportsController < ApplicationController
  def create
    archive = Archive.new

    zip_content = params[:content]
    import = Drafts::Import.create!(
      name: "#{Time.now.to_i}_#{zip_content.original_filename}",
      subject_id: Current.subject.id  # TODO add tenant option (no subject selected)
    )

    import_path = archive.store("imports", import_path(import), zip_content.read.force_encoding("UTF-8"))
    Drafts::ParseImportJob.perform_later(import, import_path)

    redirect_to drafts_path
  end

  private

  def import_path(import)
    File.join(String(Current.subject.id), import.name)
  end
end
