class FoldersController < ApplicationController
  before_action :set_folder

  def show
    # TODO - nechceme skipovat
    skip_authorization
  end

  private

  def set_folder
    @folder = Folder.find(params[:id])
  end
end
