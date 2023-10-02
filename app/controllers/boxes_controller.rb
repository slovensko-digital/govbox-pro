class BoxesController < ApplicationController
  before_action :load_box, only: %i[show sync select]

  def index
    authorize Box
    @boxes = policy_scope(Box)
  end

  def show
    authorize @box, policy_class: BoxPolicy
  end

  def sync
    authorize @box, policy_class: BoxPolicy
    raise ActionController::MethodNotAllowed.new("Not authorized") unless policy_scope(Box).exists?(@box.id)
    Govbox::SyncBoxJob.perform_later(@box)
  end

  def select
    authorize @box
    session[:box_id] = @box.id
    redirect_to request.referrer
  end

  def select_all
    authorize Box
    session[:box_id] = nil
    redirect_to request.referrer
  end

  def search
    authorize(Box)
    @boxes = policy_scope(Box)
            .where(tenant_id: Current.tenant.id)
            .where("unaccent(name) ILIKE unaccent(?) OR unaccent(short_name) ILIKE unaccent(?)", "%#{params[:name_search]}%", "%#{params[:name_search]}%")
            .order(:name)
  end

  def get_selector
    authorize(Box)
    @boxes = Current.tenant.boxes
    @all_unread_messages_count = Pundit.policy_scope(Current.user, Message).joins(thread: { folder: :box }).where(box: { tenant_id: Current.tenant.id }, read: false).count
  end

  private

  def load_box
    @box = policy_scope(Box).find(params[:id] || params[:box_id])
  end
end
