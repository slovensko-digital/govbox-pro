class TagsController < ApplicationController
  before_action :set_tag
  before_action :set_visible_tags

  def show
    authorize [:admin, @tag]
  end

  private

  def set_visible_tags
    @visible_tags = policy_scope(Tag).where(visible: true)
  end

  def set_tag
    @tag = policy_scope(Tag).find(params[:id])
  end
end
