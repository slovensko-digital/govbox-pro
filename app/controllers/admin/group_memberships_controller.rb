class Admin::GroupMembershipsController < ApplicationController
  before_action :set_group_membership, only: %i[destroy]
  # TODO - rediscuss the whole concept of SITE_ADMIN vs TENANT admin responsibilities and functionality

  def create
    # TODO: Takto mi teoreticky moze vzniknut neopravneny membership, lebo nekontrolujem tenanta. Ako spravit tak, aby som nezacal pisat exlpicitne rucne kontroly?
    @group_membership = GroupMembership.new(group_membership_params)
    authorize([:admin, @group_membership])

    if @group_membership.save
      @group = @group_membership.group
      flash[:notice] = 'Group was membership was successfully created'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    authorize([:admin, @group_membership])
    @group_membership.destroy
    redirect_to edit_members_admin_tenant_group_path(Current.tenant, @group_membership.group),
                notice: 'Group was membership was successfully deleted'
  end

  private

  def set_group_membership
    @group_membership = policy_scope([:admin,GroupMembership]).find(params[:id])
  end

  def group_membership_params
    params.require(:group_membership).permit(:group_id, :user_id)
  end
end
