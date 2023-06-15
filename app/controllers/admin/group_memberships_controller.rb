class Admin::GroupMembershipsController < ApplicationController
  before_action :set_group_membership, only: %i[ destroy ]
  # TODO - rediscuss the whole concept of SITE_ADMIN vs TENANT admin responsibilities and functionality

  def create
    @group_membership = GroupMembership.new(group_membership_params)
    authorize @group_membership, policy_class: Admin::GroupMembershipPolicy

    if @group_membership.save
      redirect_back fallback_location:"/", notice: "Group membership was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @group_membership, policy_class: Admin::GroupMembershipPolicy
    @group_membership.destroy
    redirect_back fallback_location:"/", notice: "Group membership was successfully destroyed."
  end

  private

  def set_group_membership
    @group_membership = policy_scope(GroupMembership, policy_scope_class: Admin::GroupMembershipPolicy::Scope).find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def group_membership_params
    params.require(:group_membership).permit(:group_id, :user_id)
  end
end
