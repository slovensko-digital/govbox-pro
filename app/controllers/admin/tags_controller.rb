class Admin::TagsController < ApplicationController
  before_action :set_tag, only: %i[show edit update destroy visibility_toggle]

  include TagCreation

  def index
    authorize [:admin, Tag]
    tags = policy_scope([:admin, Tag]).includes(:tenant).order(:name)

    @external_tags = tags.external
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
    params = @tag.simple? ? simple_tag_params : external_tag_params

    if @tag.update(params)
      redirect_to admin_tenant_tags_path(Current.tenant), notice: "Štítok bol úspešne upravený"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize(@tag, policy_class: Admin::TagPolicy)
    @tag.destroy
    redirect_to admin_tenant_tags_path(Current.tenant), notice: "Štítok bol úspešne odstránený"
  end

  private

  def set_tag
    @tag = Tag.find(params[:id])
  end

  def simple_tag_params
    params.require(:simple_tag).permit(:name, :visible)
  end

  def external_tag_params
    params.require(:external_tag).permit(:visible)
  end
end
