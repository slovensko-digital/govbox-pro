class GroupMembershipsController < ApplicationController
  before_action :set_group_membership, only: %i[ show edit update destroy ]
  #TODO - cleanup, lot of unused ...


  # GET /group_memberships
  def index
    authorize GroupMembership
    @group_memberships = policy_scope(GroupMembership)
  end

  # GET /group_memberships/1
  def show
  end

  # GET /group_memberships/new
  def new
    @group_membership = GroupMembership.new
    authorize @group_membership
  end

  # GET /group_memberships/1/edit
  def edit
  end

  # POST /group_memberships
  def create
    @group_membership = GroupMembership.new(group_membership_params)
    authorize @group_membership

    if @group_membership.save
      redirect_back fallback_location:"/", notice: "Group membership was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /group_memberships/1
  def update
    if @group_membership.update(group_membership_params)
      redirect_to @group_membership, notice: "Group membership was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /group_memberships/1
  def destroy
    authorize @group_membership
    @group_membership.destroy
    redirect_back fallback_location:"/", notice: "Group membership was successfully destroyed."
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_group_membership
      @group_membership = GroupMembership.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def group_membership_params
      params.require(:group_membership).permit(:group_id, :user_id)
    end
end
