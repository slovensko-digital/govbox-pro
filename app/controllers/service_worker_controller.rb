class ServiceWorkerController < ApplicationController
  protect_from_forgery except: :service_worker
  # TODO make this a one call
  skip_before_action :authenticate
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped
  skip_before_action :set_menu_context

  def service_worker
  end

  def manifest
  end
end
