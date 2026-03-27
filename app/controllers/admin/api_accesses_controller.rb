class Admin::ApiAccessesController < ApplicationController
  def show
    authorize([:admin, :api_access])
  end

  def update
    authorize([:admin, :api_access])

    if params[:delete_api_token_public_key] == "true" || api_access_params[:api_token_public_key].blank?
      Current.tenant.update(api_token_public_key: nil)
      redirect_to admin_tenant_api_access_path, notice: "Verejný kľúč bol úspešne odstránený"
      return
    end

    validator = ApiTokenPublicKeyValidator.new(api_access_params[:api_token_public_key])

    unless validator.valid?
      Current.tenant.errors.add(:api_token_public_key, validator.error_message)
      render :show, status: :unprocessable_content
      return
    end

    Current.tenant.update(api_token_public_key: validator.sanitized_key)
    redirect_to admin_tenant_api_access_path, notice: "Verejný kľúč bol úspešne aktualizovaný"
  end

  private

  def api_access_params
    params.require(:tenant).permit(:api_token_public_key)
  end
end
