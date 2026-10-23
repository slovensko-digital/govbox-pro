class FiltersController < ApplicationController
  before_action :set_filter, only: [:edit, :update, :destroy, :confirm_destroy]

  def index
    authorize Filter

    available = policy_scope(Filter, policy_scope_class: FilterPolicy::ScopeShowable)
    available = available.merge(Filter.effective_for(Current.user)) unless Current.user.admin?
    @filter_preferences = Current.user.user_filter_visibilities.index_by(&:filter_id)
    @subscriptions_by_query = Current.user.filter_subscriptions.where(filter_id: Filter.available_to(Current.user).select(:id)).includes(:filter).group_by { |subscription| subscription.filter.query }
    @filters = available.order(:position, :id).to_a.sort_by { |filter| @filter_preferences[filter.id]&.position || Float::INFINITY }
  end

  def new
    authorize Filter

    if params[:query].present?
      @filter = Filter.new(query: params[:query])
      render :new_in_modal
    else
      @filter = Filter.new
      render :new
    end
  end

  def create
    attributes = filter_params.merge(author_id: Current.user.id)
    common = ActiveModel::Type::Boolean.new.cast(attributes[:common]) || false
    scope = common ? Current.tenant.filters.common : Current.user.filters
    @filter = scope.find_by(query: attributes[:query].to_s.strip) || Current.tenant.filters.build(attributes)
    authorize @filter
    if @filter.save
      flash[:notice] = 'Filter bol úspešne vytvorený'
      if params[:to] == 'search'
        redirect_to message_threads_path(q: @filter.query)
      else
        redirect_to filters_path
      end
    else
      if params[:to] == 'search'
        redirect_to message_threads_path(q: @filter.query), alert: 'Filter sa nepodarilo vytvoriť :('
      else
        render :new, status: :unprocessable_content
      end
    end
  end

  def edit
    authorize @filter
  end

  def update
    authorize @filter

    result = @filter.update_with_confirmation(filter_params, token: params[:confirmation_token])
    if result == :updated
      redirect_to filters_path, notice: 'Filter bol úspešne uložený'
    elsif result == :confirmation_required
      @pending_filter_attributes = filter_params.to_h
      @confirmation_token = @filter.query_change_confirmation(@pending_filter_attributes)
      render :confirm_query_change, status: :unprocessable_content
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @filter
    if @filter.destroy_with_confirmation(token: params[:confirmation_token]) == :destroyed
      redirect_to filters_path, notice: 'Filter bol úspešne odstránený', status: :see_other
    else
      prepare_deletion_confirmation
      render :confirm_destroy, status: :unprocessable_content
    end
  end

  def confirm_destroy
    authorize @filter
    prepare_deletion_confirmation
  end

  private

  def prepare_deletion_confirmation
    @filter.with_lock do
      @subscribing_users_count = @filter.filter_subscriptions.distinct.count(:user_id)
      @confirmation_token = @filter.deletion_confirmation
    end
  end

  def filter_params
    permitted = [:name, :query]
    permitted << :common if action_name == "create"
    params.require(:filter).permit(*permitted)
  end

  def set_filter
    @filter = filter_scope.find(params[:id])
  end

  def filter_scope
    policy_scope(Filter, policy_scope_class: FilterPolicy::ScopeEditable).order(:position)
  end
end
