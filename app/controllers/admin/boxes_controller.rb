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

  def create
    @box = Current.tenant.boxes.new(box_params)
    authorize([:admin, @box])
    if @box.save
      redirect_to admin_tenant_boxes_url(Current.tenant), notice: "Box was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize([:admin, @box])
    if @box.update(box_params)
      redirect_to admin_tenant_boxes_url(Current.tenant), notice: "Box was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_box
    @box = Box.find(params[:id])
  end

  def box_params
    params.require(:box).permit(:api_connection_id, :name, :uri, :short_name, :color, :settings_obo)
  end
end
