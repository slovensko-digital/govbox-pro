class StickyNotesController < ApplicationController
  before_action :skip_authorization

  def destroy
    session[:sticky_note_type] = nil
    session[:sticky_note_data] = nil
    
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back(fallback_location: root_path) }
    end
  end
end
