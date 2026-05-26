module Agp
  class WebhooksController < ActionController::Base
    WEBHOOK_SIGNATURE_VERSION = "v1a".freeze

    skip_before_action :verify_authenticity_token
    before_action :authenticate

    def create
      event_type = webhook_params.require :type

      case event_type
      when "contract.signed"
        Agp::AcceptSignedContractJob.perform_later(data[:contract_id])
        head :no_content
      when "bundle.all_signed"
        head :no_content
      else
        render plain: "Unrecognized webhook event: #{event_type}", status: :unprocessable_entity
      end
    end

    private

    def webhook_params
      params.permit(:type, :timestamp, data: [:contract_id, :bundle_id])
    end

    def data
      payload_data
    end

    def authenticate
      timestamp = request.headers["webhook-timestamp"]
      hook_id = request.headers["webhook-id"]
      signature = request.headers["webhook-signature"]
      head :unauthorized and return unless signature.present? && hook_id.present? && timestamp.present? && agp_webhook_public_key.present?

      signature_version, encoded_signature = signature.to_s.split(",", 2)
      render(status: :unprocessable_entity, json: nil) and return unless signature_version == WEBHOOK_SIGNATURE_VERSION && encoded_signature.present?
      head :unauthorized and return unless valid_webhook_timestamp?(timestamp)

      data_string = "#{hook_id}.#{timestamp}.#{request.raw_post}"
      head :forbidden and return unless valid_webhook_signature?(agp_webhook_public_key, encoded_signature, data_string)
    end

    def payload_data
      params.fetch(:data, ActionController::Parameters.new).permit(:contract_id, :bundle_id)
    end

    def agp_webhook_public_key
      @agp_webhook_public_key ||= agp_tenant&.agp_webhook_public_key
    end

    def agp_tenant
      @agp_tenant ||= agp_contract&.bundle&.tenant || agp_bundle&.tenant
    end

    def agp_contract
      return @agp_contract if defined?(@agp_contract)

      @agp_contract = if payload_data[:contract_id].present?
        Agp::Contract.includes(bundle: :tenant).find_by(contract_identifier: payload_data[:contract_id])
      end
    end

    def agp_bundle
      return @agp_bundle if defined?(@agp_bundle)

      @agp_bundle = if payload_data[:bundle_id].present?
        Agp::Bundle.includes(:tenant).find_by(bundle_identifier: payload_data[:bundle_id])
      end
    end

    def valid_webhook_timestamp?(timestamp)
      parsed_timestamp = Integer(timestamp, exception: false)
      return false unless parsed_timestamp

      (Time.current.to_i - parsed_timestamp).abs <= ENV.fetch("AGP_WEBHOOK_TOLERANCE_SECONDS", 300).to_i
    end

    def valid_webhook_signature?(public_key, signature, data_string)
      digest = OpenSSL::Digest.digest("SHA256", data_string)
      key = OpenSSL::PKey::EC.new(public_key)

      key.verify_raw("SHA256", Base64.strict_decode64(signature), digest)
    rescue OpenSSL::PKey::PKeyError, ArgumentError
      false
    end
  end
end
