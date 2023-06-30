class Admin::UsersController < ApplicationController
  before_action :set_user, only: %i[show edit update destroy]

  def index
    authorize([:admin, User])
    @users = policy_scope([:admin, User])
  end

  def show
    @user = policy_scope([:admin, User]).find(params[:id])
    authorize([:admin, @user])
    @other_groups = other_groups
    @other_tags = other_tags
  end

  def new
    @user = Current.tenant.users.new
    authorize([:admin, @user])
  end

  def edit
    authorize([:admin, @user])
  end

  def create
    @user = Current.tenant.users.new(user_params)
    authorize([:admin, @user])

    respond_to do |format|
      if @user.save
        format.html { redirect_to admin_tenant_url(Current.tenant), notice: 'User was successfully created.' }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize([:admin, @user])
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to admin_tenant_url(Current.tenant), notice: 'User was successfully updated.' }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize([:admin, @user])
    @user.destroy

    respond_to do |format|
      format.html { redirect_to admin_tenant_url(Current.tenant), notice: 'User was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  def set_user
    @user = policy_scope([:admin, User]).find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :user_type)
  end

  def other_groups
    @other_groups =
      Group
      .where(tenant_id: params[:tenant_id])
      .where.not(group_type: 'USER')
      .where.not(id: Group.includes(:users).where(users: { id: @user.id }))
  end
  def other_tags
    @other_tags =
      Tag
      .where(tenant_id: params[:tenant_id])
      .where.not(id: Tag.includes(:users).where(users: { id: @user.id }))
  end
end
