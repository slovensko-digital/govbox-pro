class MessageDraftsImportsController < ApplicationController
  before_action :check_selected_box, only: :create

  def create
    authorize MessageDraftsImport

    file_storage = FileStorage.new

    zip_content = params[:content]
    import_path = file_storage.store("imports", import_path(import), zip_content.read.force_encoding("UTF-8"))

    import = MessageDraftsImport.create!(
      name: "#{Time.now.to_i}_#{zip_content.original_filename}",
      content_path: import_path,
      box: @box
    )

    Drafts::ParseImportJob.perform_later(import, author: Current.user)

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

  def check_selected_box
    return unless params[:box_id].present?

    @box = Box.find(params[:box_id].to_i)
    render_forbidden(:box_id, value: params[:box_id]) unless @box.tenant == Current.tenant
  end
end
