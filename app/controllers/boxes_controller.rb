class BoxesController < ApplicationController
  before_action :load_box, only: [:show, :sync]

  def index
    authorize Box
    @boxes = policy_scope(Box)
  end

  def show
    authorize @box, policy_class: BoxPolicy
  end

  def sync
    authorize @box, policy_class: BoxPolicy
    raise ActionController::MethodNotAllowed.new('Not authorized') unless policy_scope(Box).exists?(@box.id)
    Govbox::SyncBoxJob.perform_later(@box)
  end

  private

  def load_box
    @box = policy_scope(Box).find(params[:id] || params[:box_id])
  end
end
