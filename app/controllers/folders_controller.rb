class FoldersController < ApplicationController
  before_action :set_folder

  def show
    authorize @folder
  end

  private

  def set_folder
    @folder = policy_scope(Folder).find(params[:id])
  end
end
