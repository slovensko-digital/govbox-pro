class Admin::ApiAccessesController < ApplicationController
  def show
    authorize([:admin, :api_access])
  end

  def update
    authorize([:admin, :api_access])

    if api_access_params[:api_token_public_key].blank?
      Current.tenant.update(api_token_public_key: nil)
      redirect_to admin_tenant_api_access_path, notice: "Verejný kľúč bol úspešne odstránený" and return
    end

    if Current.tenant.update(api_access_params)
      redirect_to admin_tenant_api_access_path, notice: "Verejný kľúč bol úspešne aktualizovaný"
    else
      render :show, status: :unprocessable_content
    end
  end

  private

  def api_access_params
    params.require(:tenant).permit(:api_token_public_key)
  end
end
