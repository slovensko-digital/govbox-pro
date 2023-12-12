class FilterSubscriptionsController < ApplicationController
  before_action :set_filter

  def create
    authorize(@filter)
    s = Current.tenant.filter_subscriptions.create!(user: Current.user, filter: @filter, events: [:message_created])
    if s
      redirect_to message_threads_path(q: @filter.query), notice: "Úspešne ste sa prihlásili na odber notifikácii."
    else
    end
  end

  def destroy
    authorize(@filter)
    Current.tenant.filter_subscriptions.where(user: Current.user).find(params[:id]).destroy

    redirect_to message_threads_path(q: @filter.query), notice: "Úspešne ste sa odhlásili z odberu notifikácii."
  end

  private

  def set_filter
    @filter = Current.tenant.filters.find(params[:filter_id])
  end
end