class FiltersController < ApplicationController
  before_action :set_filter, only: [:edit, :update, :destroy]

  def index
    authorize Filter

    @filters = filter_scope
  end

  def new
    authorize Filter

    @filter = Filter.new
  end

  def create
    authorize Filter

    @filter = Current.user.filters.build(filter_params)
    if @filter.save
      flash[:notice] = 'Filter bol úspešne vytvorený'
      if params[:to] == 'search'
        redirect_to message_threads_path(q: @filter.query)
      else
        redirect_to filters_path
      end
    else
      render :new
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

  private

  def filter_params
    params.require(:filter).permit(:name, :query)
  end

  def set_filter
    @filter = filter_scope.find(params[:id])
  end

  def filter_scope
    policy_scope(Filter, policy_scope_class: FilterPolicy::Scope).order(:position)
  end
end
