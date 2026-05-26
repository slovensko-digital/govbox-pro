require "test_helper"

class Agp::AcceptSignedContractJobTest < ActiveJob::TestCase
  test "marks message object as signed by stored signer user" do
    message_object = message_objects(:ssd_main_general_draft_two_form)
    signer_user = users(:ssd_signer)
    bundle = Agp::Bundle.create!(tenant: tenants(:ssd), bundle_identifier: SecureRandom.uuid, status: :created)
    contract = Agp::Contract.create!(
      bundle: bundle,
      message_object: message_object,
      message_object_updated_at: message_object.updated_at,
      status: :created,
      signer_user: signer_user
    )

    agp_api = Struct.new(:payload) do
      def retrieve_signed_contract(_contract_id)
        payload
      end
    end.new(
      {
        "filename" => "signed.xml",
        "content_type" => "application/xml",
        "content" => Base64.strict_encode64("<signed />")
      }
    )

    signing_client = Struct.new(:api_instance) do
      def api(tenant:)
        api_instance
      end
    end.new(agp_api)

    SigningEnvironment.stub(:signing_client, signing_client) do
      Agp::AcceptSignedContractJob.perform_now(contract.contract_identifier)
    end

    assert message_object.reload.is_signed?
    assert_equal "signed.xml", message_object.name
    assert_equal "application/xml", message_object.mimetype
    assert_includes message_object.tags.reload, signer_user.signed_by_tag
  end
end
