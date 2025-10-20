class PushEndpointsController < ApplicationController
  def create
    @push_endpoint = Current.user.push_endpoints.new(push_endpoint_params)
    authorize @push_endpoint
    @push_endpoint.save
  end

  def push_endpoint_params
    params.require(:push_endpoint).permit(:endpoint, :p256dh, :auth)
  end
end
