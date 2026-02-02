# frozen_string_literal: true

module Admin
  class GroupsController < ApplicationController
    before_action :set_group, only: %i[show edit update destroy edit_members show_members edit_permissions search_non_members search_non_tags search_non_boxes]

    def index
      authorize([:admin, Group])

      @editable_groups = group_policy_scope.where(tenant_id: Current.tenant.id).editable
      @non_editable_groups = group_policy_scope.where(tenant_id: Current.tenant.id).where.not(id: @editable_groups.pluck(:id))
    end

    def show
      authorize([:admin, @group], policy_class: Admin::GroupPolicy)
    end

    def new
      @group = Current.tenant.custom_groups.new
      authorize([:admin, @group], policy_class: Admin::GroupPolicy)
    end

    def edit
      authorize([:admin, @group], policy_class: Admin::GroupPolicy)
    end

    def edit_members
      authorize([:admin, @group], policy_class: Admin::GroupPolicy)
    end

    def show_members
      authorize([:admin, @group], policy_class: Admin::GroupPolicy)
    end

    def edit_permissions
      authorize([:admin, @group], policy_class: Admin::GroupPolicy)
    end

    def create
      @group = Current.tenant.custom_groups.new(group_params)
      authorize([:admin, @group], policy_class: Admin::GroupPolicy)

      if @group.save
        redirect_to edit_members_admin_tenant_group_url(Current.tenant, @group, step: :new), notice: t('.success')
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      authorize([:admin, @group], policy_class: Admin::GroupPolicy)
      if @group.update(group_params)
        redirect_to admin_tenant_groups_url(Current.tenant), notice: t('.success')
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      authorize([:admin, @group], policy_class: Admin::GroupPolicy)
      @group.destroy
      redirect_to admin_tenant_groups_url(Current.tenant), notice: t('.success')
    end

    def search_non_members
      authorize([:admin, @group], policy_class: Admin::GroupPolicy)

      @users = params[:name_search].blank? ? [] : non_members_search_clause
    end

    def search_non_tags
      authorize([:admin, @group], policy_class: Admin::GroupPolicy)

      @tags = params[:name_search].blank? ? [] : non_tags_search_clause
    end

    def search_non_boxes
      authorize([:admin, @group], policy_class: Admin::GroupPolicy)

      @boxes = params[:name_search].blank? ? [] : non_boxes_search_clause
    end

    private

    def non_members_search_clause
      user_policy_scope
        .where(tenant: Current.tenant.id)
        .where.not(id: User.joins(:group_memberships).where(group_memberships: { group_id: @group.id }))
        .where('unaccent(name) ILIKE unaccent(?)', "%#{params[:name_search]}%")
        .order(:name)
    end

    def non_tags_search_clause
      tag_policy_scope
        .where(tenant: Current.tenant.id)
        .where.not(id: Tag.joins(:tag_groups).where(tag_groups: { group_id: @group.id }))
        .where('unaccent(name) ILIKE unaccent(?)', "%#{params[:name_search]}%")
        .order(:name)
    end

    def non_boxes_search_clause
      box_policy_scope
        .where(tenant: Current.tenant.id)
        .where.not(id: Box.joins(:box_groups).where(box_groups: { group_id: @group.id }))
        .where('unaccent(name) ILIKE unaccent(?)', "%#{params[:name_search]}%")
        .order(:name)
    end

    def set_group
      @group = group_policy_scope.find(params[:id])
    end

    def group_params
      params.require(:custom_group).permit(:name)
    end

    def group_policy_scope
      policy_scope([:admin, Group])
    end

    def user_policy_scope
      policy_scope([:admin, User])
    end

    def tag_policy_scope
      policy_scope([:admin, Tag])
    end

    def box_policy_scope
      policy_scope([:admin, Box])
    end
  end
end
