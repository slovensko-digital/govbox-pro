class Admin::ApiAccessesController < ApplicationController
  def show
    authorize([:admin, :api_access])
  end

  def update
    authorize([:admin, :api_access])

    if Current.tenant.update(normalized_api_access_params)
      redirect_to admin_tenant_api_access_path, notice: "Nastavenia API prístupu boli úspešne aktualizované"
    else
      render :show, status: :unprocessable_content
    end
  end

  private

  def api_access_params
    params.require(:tenant).permit(:api_token_public_key, :settings_agp_api_url, :settings_agp_sub, :settings_agp_api_token_private_key, :settings_agp_webhook_public_key)
  end

  def normalized_api_access_params
    api_access_params.to_h.transform_values do |value|
      value.is_a?(String) ? value.presence : value
    end
  end
end
