class Admin::TagsController < ApplicationController
  before_action :set_tag, only: %i[show edit update destroy visibility_toggle]

  def index
    authorize [:admin, Tag]
    @tags = policy_scope([:admin, Tag])
  end

  def show
    @tag = policy_scope([:admin, Tag]).find(params[:id])
    authorize([:admin, @tag])
  end

  def new
    @tag = Current.tenant.tags.new
    authorize([:admin, @tag])
  end

  def edit
    authorize([:admin, @tag])
  end

  def create
    @tag = Current.tenant.tags.new(tag_params)
    @tag.user_id = Current.user.id
    authorize([:admin, @tag])

    if @tag.save
      redirect_to admin_tenant_tags_path(Current.tenant), notice: 'Tag was successfully created'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize([:admin, @tag])
    if @tag.update(tag_params)
      redirect_to admin_tenant_tags_path(Current.tenant), notice: 'Tag was successfully updated'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize([:admin, @tag])
    @tag.destroy
    redirect_to admin_tenant_tags_path(Current.tenant), notice: 'Tag was successfully created'
  end

  private

  def set_tag
    @tag = Tag.find(params[:id])
  end

  def tag_params
    params.require(:tag).permit(:name, :visible, :user_id)
  end

  def tag_params_visibility
    params.permit(:visible)
  end
end
