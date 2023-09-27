class MessageDraftsImportsController < ApplicationController
  before_action :load_box, only: :create

  def create
    authorize MessageDraftsImport

    file_storage = FileStorage.new

    zip_content = params[:content]
    import = @box.message_drafts_imports.create!(
      name: "#{Time.now.to_i}_#{zip_content.original_filename}"
    )

    import_path = file_storage.store("imports", import_path(import), zip_content.read.force_encoding("UTF-8"))
    Drafts::ParseImportJob.perform_later(import, import_path)

    redirect_to message_drafts_path
  end

  def upload_new
    @box = Current.box if Current.box
    @box = Current.tenant.boxes.first if Current.tenant.boxes.count == 1
    authorize MessageDraftsImport
  end

  private

  def import_path(import)
    File.join(String(Current.box.id), import.name)
  end

  def load_box
    @box = Current.tenant.boxes.find(params[:box_id])
  end
end
