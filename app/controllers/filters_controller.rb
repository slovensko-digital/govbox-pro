class FiltersController < ApplicationController
  before_action :set_filter, only: [:edit, :update, :destroy, :pin, :unpin]

  def index
    authorize Filter

    @filters = filter_scope
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
    authorize Filter

    @filter = Current.tenant.filters.build(filter_params.merge({ author_id: Current.user.id }))
    if @filter.save
      flash[:notice] = 'Filter bol úspešne vytvorený'
      if params[:to] == 'search'
        redirect_to helpers.filtered_message_threads_path(filter: @filter)
      else
        redirect_to filters_path
      end
    else
      if params[:to] == 'search'
        redirect_to helpers.filtered_message_threads_path(query: @filter.query), alert: 'Filter sa nepodarilo vytvoriť :('
      else
        render :new
      end
    end
  end

  def edit
    authorize @filter
  end

  def update
    authorize @filter

    if @filter.update(filter_params)
      redirect_to filters_path, notice: 'Filter bol úspešne uložený'
    else
      redirect_to :edit
    end
  end

  def destroy
    authorize @filter
    @filter.destroy
    redirect_to filters_path, notice: 'Filter bol úspešne odstránený'
  end

  def pin
    authorize @filter
    @filter.update(is_pinned: true)
    redirect_back fallback_location: filters_path
  end

  def unpin
    authorize @filter
    @filter.update(is_pinned: false)
    redirect_back fallback_location: filters_path
  end

  private

  def filter_params
    params.require(:filter).permit(:name, :query)
  end

  def set_filter
    @filter = filter_scope.find(params[:id])
  end

  def filter_scope
    policy_scope(Filter, policy_scope_class: FilterPolicy::ScopeEditable).order(:position)
  end
end
