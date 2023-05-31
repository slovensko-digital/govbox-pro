class Admin::BoxesController < ApplicationController
  before_action :set_box, only: %i[show edit update destroy]

  def index
    authorize Box
    @boxes = policy_scope(Box)
  end

  def show
    @box = policy_scope(Box).find(params[:id])
    authorize @box, policy_class: BoxPolicy
  end

  def new
    @box = Current.tenant.boxes.new
    authorize @box
  end

  def edit
    authorize @box
  end

  def create
    @box = Current.tenant.boxes.new(box_params)
    authorize @box

    if @box.save
      redirect_to admin_tenant_url(Current.tenant), notice: "Box was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @box
    if @box.update(box_params)
      redirect_to admin_tenant_url(Current.tenant), notice: "Box was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @box
    @box.destroy
    redirect_to admin_tenant_url(Current.tenant), notice: "Box was successfully destroyed."
  end

  private

  def set_box
    @box = Box.find(params[:id])
  end

  def box_params
    params.require(:box).permit(:name, :uri)
  end
end
