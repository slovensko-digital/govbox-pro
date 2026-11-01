require "test_helper"

class Agp::ApiTest < ActiveSupport::TestCase
  setup do
    @key = OpenSSL::PKey::RSA.generate(2048)
    @stubs = Faraday::Adapter::Test::Stubs.new
    @api = Agp::Api.new("https://agp.example.test", api_token_private_key: @key.to_pem, sub: "42", handler: TestHandler.new(@stubs))
  end

  test "authenticates with a bearer token instead of a query parameter" do
    @stubs.get("/api/v1/bundles/bundle-id") do |env|
      assert_nil env.url.query
      token = env.request_headers["Authorization"].delete_prefix("Bearer ")
      payload, = JWT.decode(token, @key.public_key, true, algorithm: "RS256")
      assert_equal "42", payload["sub"]

      [200, { "Content-Type" => "application/json" }, { id: "bundle-id", contracts: [] }.to_json]
    end

    assert_equal({ "id" => "bundle-id", "contracts" => [] }, @api.retrieve_bundle("bundle-id"))
    @stubs.verify_stubbed_calls
  end

  test "returns nil for an unknown bundle and for a contract that is not signed yet" do
    @stubs.get("/api/v1/bundles/bundle-id") { [404, {}, { error: "Bundle not found" }.to_json] }
    @stubs.get("/api/v1/contracts/contract-id/signed_document") { [404, {}, { error: "No signed document available" }.to_json] }

    assert_nil @api.retrieve_bundle("bundle-id")
    assert_nil @api.retrieve_signed_document("contract-id")
  end

  test "downloads signed document following redirects" do
    @stubs.get("/api/v1/contracts/contract-id/signed_document") do
      [200, {}, { filename: "signed.asice", content_type: "application/vnd.etsi.asic-e+zip", download_url: "https://agp.example.test/rails/active_storage/blobs/redirect/blob" }.to_json]
    end
    @stubs.get("/rails/active_storage/blobs/redirect/blob") { [302, { "Location" => "/rails/active_storage/disk/file" }, ""] }
    @stubs.get("/rails/active_storage/disk/file") { [200, {}, "signed content"] }

    assert_equal(
      { filename: "signed.asice", content_type: "application/vnd.etsi.asic-e+zip", content: "signed content" },
      @api.retrieve_signed_document("contract-id")
    )
  end

  test "raises conflict for an already uploaded bundle and errors for other failures" do
    @stubs.delete("/api/v1/bundles/existing") { [409, {}, { error: "exists" }.to_json] }
    @stubs.delete("/api/v1/bundles/broken") { [500, {}, "boom"] }

    assert_raises(Agp::Api::ConflictError) { @api.destroy_bundle("existing") }
    assert_raises(Agp::Api::Error) { @api.destroy_bundle("broken") }
  end

  test "uploads bundle with webhook" do
    bundle = Agp::Bundle.find_or_create_for!(tenant: tenants(:ssd), signer_user: users(:ssd_signer), message_objects: [message_objects(:ssd_main_general_draft_two_form)])

    @stubs.post("/api/v1/bundles") do |env|
      body = JSON.parse(env.body)
      assert_equal bundle.bundle_identifier, body["id"]
      assert_equal true, body["publiclyVisible"]
      assert_equal [bundle.contracts.first.contract_identifier], body["contracts"].pluck("id")
      assert_equal({ "url" => "https://govbox.example/agp/webhooks", "method" => "standard" }, body["webhook"])

      [201, {}, { id: bundle.bundle_identifier }.to_json]
    end

    @api.stub(:generate_document_body, { filename: "form.xml" }) do
      @api.upload_bundle(bundle, webhook_url: "https://govbox.example/agp/webhooks")
    end
    @stubs.verify_stubbed_calls
  end

  # Faraday with the test adapter, the same interface as Faraday used by Agp::Api
  class TestHandler
    def initialize(stubs)
      @stubs = stubs
    end

    def new(url:, &block)
      Faraday.new(url: url) do |faraday|
        block&.call(faraday)
        faraday.adapter :test, @stubs
      end
    end

    def get(url, &)
      Faraday.new { |faraday| faraday.adapter :test, @stubs }.get(url, &)
    end
  end
end
