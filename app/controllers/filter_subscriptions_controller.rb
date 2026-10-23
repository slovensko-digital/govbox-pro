class FilterSubscriptionsController < ApplicationController
  before_action :set_filter
  before_action :set_subscription, only: [:edit, :update, :show]

  def show
  end

  def update
    path = message_threads_path(q: @subscription.filter.query)

    if @filter.with_lock { @subscription.update_or_destroy(subscription_params) }
      redirect_to path, notice: t("filter_subscription.flash.update")
    else
      redirect_to path, notice: t("filter_subscription.flash.destroy")
    end
  end

  def edit
  end

  def new
    @subscription = FilterSubscription.for_query(Current.user, @filter.query).order(:id).first || Current.user.filter_subscriptions.build(filter: @filter)
    @filter = @subscription.filter

    render :edit
  end

  def create
    Current.tenant.with_lock do
      @subscription = FilterSubscription.for_query(Current.user, @filter.query).order(:id).first
      # Query controls may target a personal display match while editing an
      # existing common source. Serialize against deletion of that actual source.
      @filter = @subscription.filter if @subscription
      @filter.with_lock do
        Current.user.with_lock do
          if @subscription
            @subscription.reload
            @subscription.update_or_destroy(params.permit(events: []))
          else
            @subscription = Current.user.filter_subscriptions.create(subscription_params)
          end
        end
      end
    end

    if @subscription.valid?
      redirect_to message_threads_path(q: @subscription.filter.query), notice: t("filter_subscription.flash.create")
    else
      redirect_to message_threads_path(q: @subscription.filter.query)
    end
  end

  private

  def subscription_params
    params.permit(events: []).merge(filter: @filter, tenant: Current.tenant)
  end

  def set_filter
    @filter = policy_scope(Filter, policy_scope_class: FilterPolicy::ScopeShowable).find(params[:filter_id])
    authorize @filter, :subscribe?
  end

  def set_subscription
    @subscription = Current.user.filter_subscriptions.where(tenant_id: Current.user.tenant_id, filter_id: @filter.id).find(params[:id])
  end
end
