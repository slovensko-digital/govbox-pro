class Admin::TagsController < ApplicationController
  before_action :set_tag, only: %i[show edit update destroy]

  include TagCreation

  def index
    authorize [:admin, Tag]
    tags = policy_scope([:admin, Tag]).includes(:tenant).order(:name)

    @simple_tags = tags.simple
  end

  def show
    @tag = policy_scope([:admin, Tag]).find(params[:id])
    authorize([:admin, @tag])
  end

  def new
    @tag = SimpleTag.new
    authorize(@tag, policy_class: Admin::TagPolicy)
  end

  def edit
    authorize(@tag, policy_class: Admin::TagPolicy)
  end

  def create
    @tag = SimpleTag.new(simple_tag_params.merge(simple_tag_creation_params))
    authorize(@tag, policy_class: Admin::TagPolicy)

    if @tag.save
      redirect_to admin_tenant_tags_path(Current.tenant), notice: "Štítok bol úspešne vytvorený"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize(@tag, policy_class: Admin::TagPolicy)

    if @tag.update(simple_tag_params)
      redirect_to admin_tenant_tags_path(Current.tenant), notice: "Štítok bol úspešne upravený"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize(@tag, policy_class: Admin::TagPolicy)
    if @tag.destroy
      redirect_to admin_tenant_tags_path(Current.tenant), notice: "Štítok bol úspešne odstránený"
    else
      redirect_to admin_tenant_tags_path(Current.tenant), alert: @tag.errors.full_messages[0]
    end
  end

  private

  def set_tag
    @tag = SimpleTag.find(params[:id])
  end

  def simple_tag_params
    params.require(:simple_tag).permit(:name, :visible, :quick, :color, :icon)
  end
end
