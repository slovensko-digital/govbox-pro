class Admin::GroupsController < ApplicationController
  before_action :set_group, only: %i[ show edit update destroy ]

  def index
    authorize([:admin, Group])
    @groups = policy_scope([:admin, Group])
  end

  def show
    @group = policy_scope([:admin, Group]).find(params[:id])
    authorize([:admin, @group])
    @other_tags = other_tags
  end

  def new
    @group = Current.tenant.groups.new
    authorize([:admin, @group])
  end

  def edit
    authorize([:admin, @group])
  end

  def create
    @group = Current.tenant.groups.new(group_params)
    authorize([:admin, @group])

    if @group.save
      redirect_to admin_tenant_url(Current.tenant), notice: "Group was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize([:admin, @group])
    if @group.update(group_params)
      redirect_to admin_tenant_url(Current.tenant), notice: "Group was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize([:admin, @group])
    @group.destroy
    redirect_to admin_tenant_url(Current.tenant), notice: "Group was successfully destroyed."
  end

  private
  def set_group
    @group = Group.find(params[:id])
  end

  def group_params
    params.require(:group).permit(:name, :group_type)
  end

  def other_tags
    @other_tags =
      Tag
        .where(tenant_id: params[:tenant_id])
        .where.not(id: @group.tag_ids)
  end
end
