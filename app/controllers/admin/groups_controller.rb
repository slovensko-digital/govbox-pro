class Admin::GroupsController < ApplicationController
  before_action :set_group, only: %i[show edit update destroy edit_members show_members edit_permissions search_non_members search_non_tags]

  def index
    authorize([:admin, Group])
    @custom_groups = policy_scope([:admin, Group]).where(tenant_id: Current.tenant.id).where.not(group_type: %w[ALL USER])
    @system_groups = policy_scope([:admin, Group]).where(tenant_id: Current.tenant.id, group_type: %w[ALL USER])
  end

  def show
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

  def edit_members
    authorize([:admin, @group])
  end

  def show_members
    authorize([:admin, @group])
  end

  def edit_permissions
    authorize([:admin, @group])
  end

  def create
    @group = Current.tenant.groups.new(group_params)
    @group.group_type = 'CUSTOM'
    authorize([:admin, @group])

    if @group.save
      redirect_to edit_members_admin_tenant_group_url(Current.tenant, @group, step: :new), notice: 'Group was successfully created'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize([:admin, @group])
    if @group.update(group_params)
      redirect_to admin_tenant_groups_url(Current.tenant), notice: 'Group was successfully updated'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize([:admin, @group])
    @group.destroy
    redirect_to admin_tenant_groups_url(Current.tenant), notice: 'Group was successfully destroyed'
  end

  def search_non_members
    authorize([:admin, @group])
    return if params[:name_search].blank?

    @users = non_members_search_clause
  end

  def search_non_tags
    authorize([:admin, @group])
    return if params[:name_search].blank?

    @tags = non_tags_search_clause
  end

  private

  def non_members_search_clause
    policy_scope([:admin, User])
      .where(tenant: Current.tenant.id)
      .where.not(id: User.joins(:group_memberships).where(group_memberships: { group_id: @group.id }))
      .where('unaccent(name) ILIKE unaccent(?)', "%#{params[:name_search]}%")
      .order(:name)
  end

  def non_tags_search_clause
    policy_scope([:admin, Tag])
      .where(tenant: Current.tenant.id)
      .where.not(id: Tag.joins(:tag_groups).where(tag_groups: { group_id: @group.id }))
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
