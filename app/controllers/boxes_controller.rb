class BoxesController < ApplicationController
  before_action :load_box, only: [:show, :sync]

  def index
    @boxes = policy_scope(Box)
    authorize Box
  end

  def show
  end

  def sync
    Govbox::SyncBoxJob.perform_later(@box)
  end

  private

  def load_box
    @box = policy_scope(Box).find(params[:id] || params[:box_id])
    authorize @box
  end
end
