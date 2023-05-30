class BoxesController < ApplicationController
  before_action :load_boxes, only: :index
  before_action :load_box, only: [:show, :sync]

  # TODO fix: this is temporary
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  def index
  end

  def show
  end

  def sync
    Govbox::SyncBoxJob.perform_later(@box)
  end

  private

  def load_box
    @box = Current.box
  end

  def load_boxes
    @boxes = Current.tenant.boxes
  end
end
