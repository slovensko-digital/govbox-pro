class TagsController < ApplicationController
  before_action :set_tag

  def show
    authorize @tag
  end

  private

  def set_tag
    @tag = policy_scope(Tag).find(params[:id])
  end
end
