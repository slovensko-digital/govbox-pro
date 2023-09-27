class MessageDraftsImportsController < ApplicationController
  before_action :check_selected_box, only: :create

  def create
    authorize MessageDraftsImport

    zip_content = params[:content]
    import_name = "#{Time.now.to_i}_#{zip_content.original_filename}"
    import_path = FileStorage.new.store("imports", import_path(import_name), zip_content.read.force_encoding("UTF-8"))

    import = MessageDraftsImport.create(
      name: import_name,
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

  def import_path(import_name)
    File.join(String(@box.id), import_name)
  end

  def check_selected_box
    return unless params[:box_id].present?

    @box = Box.find(params[:box_id].to_i)
    render_forbidden(:box_id, value: params[:box_id]) unless @box.tenant == Current.tenant
  end
end
