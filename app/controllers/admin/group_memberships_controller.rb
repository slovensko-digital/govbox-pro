class Admin::GroupMembershipsController < ApplicationController
  before_action :set_group_membership, only: %i[destroy]

  def create
    @group = Current.tenant.groups.find(group_membership_params[:group_id])
    @group_membership = @group.group_memberships.build(group_membership_params)
    authorize([:admin, @group_membership])

    if @group_membership.save
      @group = @group_membership.group
      flash[:notice] = 'Group membership was successfully created'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    authorize([:admin, @group_membership])
    if @group_membership.destroy
      redirect_to edit_members_admin_tenant_group_path(Current.tenant, @group_membership.group),
                  notice: 'Group was membership was successfully deleted'
    else
      flash[:alert] = @group_membership.errors.full_messages[0]
      redirect_to edit_members_admin_tenant_group_path(Current.tenant, @group_membership.group)
    end
  end

  private

  def set_group_membership
    @group_membership = policy_scope([:admin, GroupMembership]).find(params[:id])
  end

  def group_membership_params
    params.require(:group_membership).permit(:group_id, :user_id)
  end
end
