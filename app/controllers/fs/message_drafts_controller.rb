class Fs::MessageDraftsController < ApplicationController
  def new
    @message = MessageDraft.new
    @boxes = Current.tenant&.boxes.where(type: 'Fs::Box')
    @box = Current.box

    authorize @message
  end
end
