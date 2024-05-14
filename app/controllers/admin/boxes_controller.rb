class Admin::BoxesController < ApplicationController
  before_action :set_box, only: %i[show edit update]

  def index
    authorize Box
    @boxes = policy_scope([:admin, Box]).order(:name)
  end

  def show
    @box = policy_scope([:admin, Box]).find(params[:id])
    authorize([:admin, @box])
  end

  def new
    @box = Current.tenant.boxes.new
    authorize([:admin, @box])
  end

  def edit
    authorize([:admin, @box])
  end

  def update
    raise NotImplementedError
  end

  private

  def set_box
    @box = Box.find(params[:id])
  end
end
