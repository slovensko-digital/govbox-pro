class Api::SiteAdmin::Upvs::BoxesController < Api::SiteAdminController
  def create
    Box.transaction do
      @box = Upvs::Box.create_with_api_connection!(box_params)
    end
  end

  private

  def box_params
    params.require(:box).permit(:name, :short_name, :uri, :color, :api_connection_id,
                                :settings_obo, api_connection: [:sub, :api_token_private_key]).merge(tenant_id: params[:tenant_id])
          .transform_values! { |value| value.present? ? value : nil }
  end
end
