class StickyNotesController < ApplicationController
  def destroy
    session[:sticky_note_type] = nil
    session[:sticky_note_data] = nil
  end
end
