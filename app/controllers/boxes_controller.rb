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
    # TODO: Ako toto riesit? Toto funguje, ale je ako z 80ich rokov. Dalsia session premenna?
    session[:box_id] = nil
    redirect_to request.referrer
  end

  def search
    authorize(Box)
    @boxes = policy_scope(Box)
            .where(tenant_id: Current.tenant.id).where("unaccent(name) ILIKE unaccent(?)", "%#{params[:name_search]}%")
            .or(policy_scope(Box).where(tenant_id: Current.tenant.id).where("unaccent(short_name) ILIKE unaccent(?)", "%#{params[:name_search]}%"))
            .order(:name)
  end

  private

  def load_box
    @box = policy_scope(Box).find(params[:id] || params[:box_id])
  end
end
