class FilterSubscriptionsController < ApplicationController
  before_action :set_filter
  before_action :set_subscription, only: [:edit, :update, :show]
  skip_after_action :verify_authorized

  def show
  end

  def update
    path = message_threads_path(q: @subscription.filter.query)

    if @subscription.update_or_destroy(subscription_params)
      redirect_to path, notice: t("filter_subscription.flash.update")
    else
      redirect_to path, notice: t("filter_subscription.flash.destroy")
    end
  end

  def edit
  end

  def new
    @subscription = Current.user.filter_subscriptions.build

    render :edit
  end

  def create
    @subscription = Current.user.filter_subscriptions.create(subscription_params)

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
    @filter = Current.tenant.filters.find(params[:filter_id])
  end

  def set_subscription
    @subscription = Current.user.filter_subscriptions.find(params[:id])
  end
end