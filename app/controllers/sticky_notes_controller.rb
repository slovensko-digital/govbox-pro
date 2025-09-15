class StickyNotesController < ApplicationController
  skip_after_action :verify_authorized

  def destroy
    Current.user.sticky_note&.destroy
    
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to root_path }
    end
  end
end
