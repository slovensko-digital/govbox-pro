module Agp
  class WebhooksController < ActionController::Base
    skip_before_action :verify_authenticity_token
    before_action :authenticate

    def create
      event_type = webhook_params.require :type

      case event_type
      when "contract.signed"
        Agp::AcceptSignedContractJob.perform_later(data[:contract_id])
      when "bundle.all_signed"
        # OK, nothing to do
        head :no_content and return
      else
        render text: "Unrecognized webhook event: #{event_type}", status: :unprocessable_entity
      end
    end

    private

    def webhook_params
      params.permit(:type, :timestamp, data: [:contract_id, :bundle_id])
    end

    def data
      params.require(:data).permit(:contract_id, :bundle_id)
    end

    def authenticate
      # TODO real authentication
      return

      timestamp = request.headers["webhook-timestamp"]
      hook_id = request.headers["webhook-id"]
      signature = request.headers["webhook-signature"]
      render(status: :unauthorized, json: nil) and return unless signature.present? && hook_id.present? && timestamp.present?

      data_string = "#{hook_id}.#{timestamp}.#{request.body.read}"

      if signature.starts_with? "v1a,"
        hash = OpenSSL::Digest.digest("SHA256", data_string)
        key = OpenSSL::PKey::EC.new(@tenant.ops_webhook_public_key)
        render status: :forbidden, json: nil unless key.verify_raw("SHA256", Base64.decode64(signature.gsub("v1a,", "")), hash)

      elsif signature.starts_with? "v1,"
        key = @tenant.ops_webhook_public_key
        expected_signature = OpenSSL::HMAC.base64digest("SHA256", key, data_string)
        render status: :forbidden, json: nil unless ActiveSupport::SecurityUtils.secure_compare(expected_signature, signature.gsub("v1,", ""))

      else
        render status: :unprocessable_entity, json: { message: "Unrecognized webhook-signature prefix" }
      end
    end
  end
end
