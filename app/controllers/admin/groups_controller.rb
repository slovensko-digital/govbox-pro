class Admin::GroupsController < ApplicationController
  before_action :set_group, only: %i[ show edit update destroy ]

  def index
    authorize Group, policy_class: Admin::GroupPolicy
    @groups = policy_scope(Group, policy_scope_class: Admin::GroupPolicy::Scope)
  end

  def show
    @group = policy_scope(Group, policy_scope_class: Admin::GroupPolicy::Scope).find(params[:id])
    authorize @group, policy_class: Admin::GroupPolicy
  end

  def new
    @group = Current.tenant.groups.new
    authorize @group, policy_class: Admin::GroupPolicy
  end

  def edit
    authorize @group, policy_class: Admin::GroupPolicy
  end

  def create
    @group = Current.tenant.groups.new(group_params)
    authorize @group, policy_class: Admin::GroupPolicy

    if @group.save
      redirect_to admin_tenant_url(Current.tenant), notice: "Group was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @group, policy_class: Admin::GroupPolicy
    if @group.update(group_params)
      redirect_to admin_tenant_url(Current.tenant), notice: "Group was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @group, policy_class: Admin::GroupPolicy
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
end
