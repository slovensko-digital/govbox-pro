class Upvs::MessageDraftsImportsController < ApplicationController
  before_action :load_box, only: :create

  def create
    authorize MessageDraftsImport

    zip_content = params[:content]
    import_name = "#{Time.now.to_i}_#{zip_content.original_filename}"
    import_path = FileStorage.new.store("imports", import_path(import_name), zip_content.read.force_encoding("UTF-8"))

    import = @box.message_drafts_imports.create!(
      name: import_name,
      content_path: import_path,
      box: @box
    )

    Upvs::Drafts::ParseImportJob.perform_later(import, author: Current.user)

    redirect_to upvs_message_drafts_path
  end

  def upload_new
    @box = Current.box if Current.box
    @box = Current.tenant.boxes.first if Current.tenant.boxes.count == 1
    authorize MessageDraftsImport
  end

  private

  def import_path(import_name)
    File.join(String(@box.id), import_name)
  end

  def load_box
    @box = Current.tenant.boxes.find(params[:box_id])
  end
end
