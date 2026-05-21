require "test_helper"

class Agp::WebhooksControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @tenant = tenants(:ssd)
    @message_object = message_objects(:ssd_main_general_draft_two_form)
    @bundle = Agp::Bundle.create!(tenant: @tenant, bundle_identifier: SecureRandom.uuid, status: :created)
    @contract = Agp::Contract.create!(
      bundle: @bundle,
      message_object: @message_object,
      message_object_updated_at: @message_object.updated_at,
      status: :created,
      signer_user: users(:ssd_signer)
    )
    @webhook_key_pair = OpenSSL::PKey::EC.generate("prime256v1")
    @tenant.update!(settings_agp_webhook_public_key: @webhook_key_pair.public_to_pem)
  end

  test "accepts valid contract signed webhook and enqueues accept job" do
    payload = {
      type: "contract.signed",
      timestamp: Time.current.iso8601,
      data: {
        contract_id: @contract.contract_identifier,
        bundle_id: @bundle.bundle_identifier
      }
    }

    request_body = payload.to_json
    headers = webhook_headers_for(request_body)

    assert_enqueued_with(job: Agp::AcceptSignedContractJob, args: [@contract.contract_identifier]) do
      post agp_webhooks_path, params: request_body, headers: headers
    end

    assert_response :no_content
  end

  test "accepts valid bundle all signed webhook" do
    payload = {
      type: "bundle.all_signed",
      timestamp: Time.current.iso8601,
      data: {
        bundle_id: @bundle.bundle_identifier
      }
    }

    request_body = payload.to_json

    post agp_webhooks_path, params: request_body, headers: webhook_headers_for(request_body)

    assert_response :no_content
  end

  test "rejects webhook with invalid signature" do
    payload = {
      type: "contract.signed",
      timestamp: Time.current.iso8601,
      data: {
        contract_id: @contract.contract_identifier,
        bundle_id: @bundle.bundle_identifier
      }
    }

    request_body = payload.to_json
    headers = webhook_headers_for(request_body)
    headers["webhook-signature"] = "v1a,#{Base64.strict_encode64("invalid") }"

    post agp_webhooks_path, params: request_body, headers: headers

    assert_response :forbidden
    assert_no_enqueued_jobs
  end

  test "accepts valid webhook when env fallback key uses escaped newlines" do
    @tenant.update!(settings_agp_webhook_public_key: nil)

    payload = {
      type: "contract.signed",
      timestamp: Time.current.iso8601,
      data: {
        contract_id: @contract.contract_identifier,
        bundle_id: @bundle.bundle_identifier
      }
    }

    request_body = payload.to_json

    with_env_webhook_public_key(@webhook_key_pair.public_to_pem.gsub("\n", "\\n")) do
      assert_enqueued_with(job: Agp::AcceptSignedContractJob, args: [@contract.contract_identifier]) do
        post agp_webhooks_path, params: request_body, headers: webhook_headers_for(request_body)
      end
    end

    assert_response :no_content
  end

  private

  def with_env_webhook_public_key(value)
    original_value = ENV.fetch("AGP_WEBHOOK_PUBLIC_KEY", nil)
    ENV["AGP_WEBHOOK_PUBLIC_KEY"] = value

    yield
  ensure
    ENV["AGP_WEBHOOK_PUBLIC_KEY"] = original_value
  end

  def webhook_headers_for(request_body, timestamp: Time.current.to_i, webhook_id: SecureRandom.uuid)
    signature_payload = "#{webhook_id}.#{timestamp}.#{request_body}"
    digest = OpenSSL::Digest.digest("SHA256", signature_payload)
    signature = @webhook_key_pair.sign_raw("SHA256", digest)

    {
      "CONTENT_TYPE" => "application/json",
      "webhook-id" => webhook_id,
      "webhook-timestamp" => timestamp.to_s,
      "webhook-signature" => "v1a,#{Base64.strict_encode64(signature)}"
    }
  end
end
