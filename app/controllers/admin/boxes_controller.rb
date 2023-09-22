class Admin::BoxesController < ApplicationController
  before_action :set_box, only: %i[show edit update destroy]

  def index
    authorize Box
    @boxes = policy_scope([:admin, Box])
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
    @box.color = Box.colors.keys[Digest::MD5.hexdigest(@box.name).to_i(16) % Box.colors.size]

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

  def destroy
    authorize([:admin, @box])
    @box.destroy
    redirect_to admin_tenant_boxes_url(Current.tenant), notice: "Box was successfully destroyed."
  end

  private

  def set_box
    @box = Box.find(params[:id])
  end

  def box_params
    params.require(:box).permit(:name, :uri, :short_name, :color)
  end
end
