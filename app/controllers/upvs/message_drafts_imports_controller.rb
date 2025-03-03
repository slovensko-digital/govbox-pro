class Upvs::MessageDraftsImportsController < ApplicationController
  before_action :ensure_drafts_import_enabled
  before_action :load_box, only: :create

  def new
    @box = Current.box if Current.box
    @box = Current.tenant.boxes.first if Current.tenant.boxes.count == 1
    authorize MessageDraftsImport
  end

  def create
    authorize MessageDraftsImport

    redirect_back fallback_location: new_upvs_message_drafts_import_path, alert: 'Nahrajte import' and return unless params[:content].present?

    zip_content = params[:content]
    import_name = "#{Time.now.to_i}_#{zip_content.original_filename}"
    import_path = FileStorage.new.store("imports", import_path(import_name), zip_content.read.force_encoding("UTF-8"))

    import = @box.message_drafts_imports.create!(
      name: import_name,
      content_path: import_path,
      box: @box
    )

    Upvs::Drafts::ParseImportJob.set(job_context: :later).perform_later(import, author: Current.user)

    redirect_to message_threads_path(q: "label:(#{Current.tenant.draft_tag.name})")
  end

  private

  def ensure_drafts_import_enabled
    redirect_to message_threads_path(q: "label:(#{Current.tenant.draft_tag.name})") unless Current.tenant.feature_enabled?(:message_draft_import)
  end

  def import_path(import_name)
    File.join(String(@box.id), import_name)
  end

  def load_box
    @box = Current.tenant.boxes.find(params[:box_id])
  end
end
