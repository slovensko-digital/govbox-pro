class Api::SiteAdmin::Fs::BoxesController < Api::SiteAdminController
  def create
    Box.transaction do
      @box = Fs::Box.create_with_api_connection!(box_params)
    end
  end

  private
  def box_params
    params.require(:box).permit(:name, :short_name, :export_name, :uri, :color, :api_connection_id,
                                settings: [:obo, :dic, :subject_id], api_connection: [:sub, :api_token_private_key, settings: [:username, :password]]).merge(tenant_id: params[:tenant_id])
  end
end
