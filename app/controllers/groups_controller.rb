class GroupsController < ApplicationController
  before_action :set_group, only: %i[ show edit update destroy ]

  # GET /groups
  def index
    authorize Group
    @groups = policy_scope(Group)
  end

  # GET /groups/1
  def show
    @group = policy_scope(Group).find(params[:id])
    authorize @group, policy_class: GroupPolicy
  end

  # GET /groups/new
  def new
    @group = Current.tenant.groups.new
    authorize @group
  end

  # GET /groups/1/edit
  def edit
    authorize @group
  end

  # POST /groups
  def create
    @group = Current.tenant.groups.new(group_params)
    authorize @group

    if @group.save
      redirect_to Current.tenant, notice: "Group was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /groups/1
  def update
    authorize @group
    if @group.update(group_params)
      redirect_to Current.tenant, notice: "Group was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /groups/1
  def destroy
    authorize @group
    @group.destroy
    redirect_to Current.tenant, notice: "Group was successfully destroyed."
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_group
      @group = Group.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def group_params
      params.require(:group).permit(:name, :group_type)
    end
end
