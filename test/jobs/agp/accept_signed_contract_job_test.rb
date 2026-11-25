require "test_helper"

class Agp::AcceptSignedContractJobTest < ActiveJob::TestCase
  setup do
    @message_object = message_objects(:ssd_main_general_draft_two_form)
    @signer_user = users(:ssd_signer)
    @bundle = Agp::Bundle.create!(tenant: tenants(:ssd), status: :created)
    @contract = Agp::Contract.build_for(@message_object, signer_user: @signer_user)
    @contract.update!(bundle: @bundle, status: :created)
  end

  test "marks message object as signed by stored signer user and completes the bundle" do
    api = FakeApi.new({ filename: "signed.xml", content_type: "application/xml", content: "<signed />" })

    Agp.stub(:api_for, api) do
      Agp::AcceptSignedContractJob.perform_now(@contract.contract_identifier)
    end

    assert @message_object.reload.is_signed?
    assert_equal "signed.xml", @message_object.name
    assert_equal "application/xml", @message_object.mimetype
    assert_equal "<signed />", @message_object.content
    assert_includes @message_object.tags.reload, @signer_user.signed_by_tag
    assert @contract.reload.completed?
    assert @bundle.reload.completed?
    assert_equal [@contract.contract_identifier], api.requested
  end

  test "is idempotent" do
    api = FakeApi.new({ filename: "signed.xml", content_type: "application/xml", content: "<signed />" })

    Agp.stub(:api_for, api) do
      2.times { Agp::AcceptSignedContractJob.perform_now(@contract.contract_identifier) }
    end

    assert_equal 1, api.requested.size
  end

  test "does nothing while the contract is not signed" do
    Agp.stub(:api_for, FakeApi.new(nil)) do
      Agp::AcceptSignedContractJob.perform_now(@contract.contract_identifier)
    end

    assert_not @message_object.reload.is_signed?
    assert @contract.reload.created?
  end

  test "rejects signed document when the message object changed after it was sent to signing" do
    @message_object.message_object_datum.update!(blob: "<changed />")

    Agp.stub(:api_for, FakeApi.new({ filename: "signed.xml", content_type: "application/xml", content: "<signed />" })) do
      Agp::AcceptSignedContractJob.perform_now(@contract.contract_identifier)
    end

    assert_equal "<changed />", @message_object.reload.content
    assert_not @message_object.is_signed?
    assert @contract.reload.failed?
    assert @bundle.reload.failed?
  end

  test "ignores unknown contracts" do
    assert_nothing_raised do
      Agp::AcceptSignedContractJob.perform_now(SecureRandom.uuid)
    end
  end

  class FakeApi
    attr_reader :requested

    def initialize(signed_document)
      @signed_document = signed_document
      @requested = []
    end

    def retrieve_signed_document(contract_identifier)
      @requested << contract_identifier
      @signed_document
    end
  end
end
