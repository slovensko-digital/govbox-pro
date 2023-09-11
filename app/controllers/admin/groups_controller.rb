class Admin::GroupsController < ApplicationController
  before_action :set_group, only: %i[show edit update destroy edit_members search_non_members]

  def index
    authorize([:admin, Group])
    @custom_groups = policy_scope([:admin, Group]).where(tenant_id: Current.tenant.id).where.not(group_type: %w[ALL USER])
    @system_groups = policy_scope([:admin, Group]).where(tenant_id: Current.tenant.id, group_type: %w[ALL USER])
  end

  def show
    authorize([:admin, @group])
  end

  def new
    @group = Current.tenant.groups.new
    authorize([:admin, @group])
  end

  def edit
    authorize([:admin, @group])
  end

  def edit_members
    authorize([:admin, @group])
  end

  def create
    @group = Current.tenant.groups.new(group_params)
    authorize([:admin, @group])

    if @group.save
      redirect_to edit_members_admin_tenant_group_url(Current.tenant, @group, step: :new), notice: 'Group was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize([:admin, @group])
    if @group.update(group_params)
      flash[:notice] = 'Group was successfully updated'
      render turbo_stream: turbo_stream.action(:redirect, admin_tenant_groups_url)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize([:admin, @group])
    @group.destroy
    flash[:notice] = 'Group was successfully updated'
    render turbo_stream: turbo_stream.action(:redirect, admin_tenant_groups_url)
  end

  def search_non_members
    authorize([:admin, @group])
    return if params[:name_search].blank?

    @users = non_members_search_clause
  end

  private

  def non_members_search_clause
    policy_scope([:admin, User])
      .where(tenant: Current.tenant.id)
      .where.not(id: User.joins(:group_memberships).where(group_memberships: { group_id: @group.id }))
      .where('unaccent(name) ILIKE unaccent(?)', "%#{params[:name_search]}%")
      .order(:name)
  end

  def set_group
    @group = policy_scope([:admin, Group]).find(params[:id])
  end

  def group_params
    params.require(:group).permit(:name, :group_type)
  end
end
