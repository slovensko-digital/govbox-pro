class Admin::UsersController < ApplicationController
  before_action :set_user, only: %i[ show edit update destroy ]

  def index
    authorize User
    @users = policy_scope(User)
  end

  def show
    @user = policy_scope(User).find(params[:id])
    authorize @user, policy_class: UserPolicy
    @other_groups = Group.where(tenant_id: params[:tenant_id])
      .where.not(group_type: 'USER')
      .where.not(
        id:
          Group.includes(:users).where(users: {id: @user.id}),
      )
  end

  def new
    @user = Current.tenant.users.new
    authorize @user
  end

  def edit
    authorize @user
  end

  def create
    @user = Current.tenant.users.new(user_params)
    authorize @user

    respond_to do |format|
      if @user.save
        format.html { redirect_to admin_tenant_url(Current.tenant), notice: "User was successfully created." }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize @user
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to admin_tenant_url(Current.tenant), notice: "User was successfully updated." }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize @user
    @user.destroy

    respond_to do |format|
      format.html { redirect_to admin_tenant_url(Current.tenant), notice: "User was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    def set_user
      @user = policy_scope(User).find(params[:id])
    end

    def user_params
      params.require(:user).permit(:name, :email, :user_type)
    end
end
