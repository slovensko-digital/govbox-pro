class Drafts::ImportsController < ApplicationController
  def create
    authorize Drafts::Import, policy_class: Drafts::ImportPolicy

    file_storage = FileStorage.new

    zip_content = params[:content]
    import = Drafts::Import.create!(
      name: "#{Time.now.to_i}_#{zip_content.original_filename}",
      box: Current.box
    )

    import_path = file_storage.store("imports", import_path(import), zip_content.read.force_encoding("UTF-8"))
    Drafts::ParseImportJob.perform_later(import, import_path)

    redirect_to drafts_path
  end

  def upload_new
    authorize Drafts::Import, policy_class: Drafts::ImportPolicy
  end

  private

  def import_path(import)
    File.join(String(Current.box.id), import.name)
  end
end
