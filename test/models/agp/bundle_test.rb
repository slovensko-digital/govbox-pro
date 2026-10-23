require "test_helper"

class Agp::BundleTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @tenant = tenants(:ssd)
    @signer_user = users(:ssd_signer)
    @message_object = message_objects(:ssd_main_general_draft_two_form)
  end

  test "find_or_create_for! creates bundle with random identifier and contracts of the signer user" do
    bundle = Agp::Bundle.find_or_create_for!(tenant: @tenant, signer_user: @signer_user, message_objects: [@message_object])

    assert bundle.persisted?
    assert bundle.init?
    assert_match(/\A\h{8}-\h{4}-4\h{3}-\h{4}-\h{12}\z/, bundle.bundle_identifier)
    assert_equal [@signer_user], bundle.contracts.map(&:signer_user)
    assert_equal [Digest::SHA256.hexdigest(@message_object.content)], bundle.contracts.map(&:content_digest)
  end

  test "find_or_create_for! reuses recent pending bundle for unchanged documents" do
    bundle = Agp::Bundle.find_or_create_for!(tenant: @tenant, signer_user: @signer_user, message_objects: [@message_object])
    bundle.update!(status: :created)

    assert_equal bundle, Agp::Bundle.find_or_create_for!(tenant: @tenant, signer_user: @signer_user, message_objects: [@message_object])
  end

  test "find_or_create_for! does not reuse bundle of another signer, with changed content, finished or old" do
    bundle = Agp::Bundle.find_or_create_for!(tenant: @tenant, signer_user: @signer_user, message_objects: [@message_object])

    assert_not_equal bundle, Agp::Bundle.find_or_create_for!(tenant: @tenant, signer_user: users(:ssd_signer2), message_objects: [@message_object])

    @message_object.message_object_datum.update!(blob: "<changed />")
    changed_bundle = Agp::Bundle.find_or_create_for!(tenant: @tenant, signer_user: @signer_user, message_objects: [@message_object])
    assert_not_equal bundle, changed_bundle

    changed_bundle.update!(status: :completed)
    assert_not_equal changed_bundle, Agp::Bundle.find_or_create_for!(tenant: @tenant, signer_user: @signer_user, message_objects: [@message_object])

    travel_to (Agp::Bundle::REUSABLE_FOR + 1.minute).from_now do
      assert Agp::Bundle.find_or_create_for!(tenant: @tenant, signer_user: @signer_user, message_objects: [@message_object]).init?
      assert_equal 5, Agp::Bundle.where(tenant: @tenant).count
    end
  end

  test "upload! marks bundle as created and schedules polling" do
    bundle = Agp::Bundle.find_or_create_for!(tenant: @tenant, signer_user: @signer_user, message_objects: [@message_object])
    api = Minitest::Mock.new
    api.expect(:upload_bundle, nil, [bundle], webhook_url: "https://govbox.example/agp/webhooks")

    assert_enqueued_with(job: Agp::SyncBundleJob, args: [bundle, { poll: true }]) do
      bundle.upload!(webhook_url: "https://govbox.example/agp/webhooks", api: api)
    end

    api.verify
    assert bundle.reload.created?
    assert bundle.contracts.all?(&:created?)
  end

  test "upload! treats conflict as an earlier successful upload" do
    bundle = Agp::Bundle.find_or_create_for!(tenant: @tenant, signer_user: @signer_user, message_objects: [@message_object])
    api = FailingUploadApi.new(Agp::Api::ConflictError.new("exists"))

    bundle.upload!(webhook_url: "https://govbox.example/agp/webhooks", api: api)

    assert bundle.reload.created?
  end

  test "upload! marks bundle as failed and reraises errors" do
    bundle = Agp::Bundle.find_or_create_for!(tenant: @tenant, signer_user: @signer_user, message_objects: [@message_object])
    api = FailingUploadApi.new(Agp::Api::Error.new("boom"))

    assert_raises(Agp::Api::Error) do
      bundle.upload!(webhook_url: "https://govbox.example/agp/webhooks", api: api)
    end

    assert bundle.reload.init_failed?
    assert_no_enqueued_jobs only: Agp::SyncBundleJob
  end

  test "sync! accepts signed contracts and leaves the others pending" do
    other_message_object = message_objects(:ssd_main_general_draft_three_form)
    bundle = created_bundle([@message_object, other_message_object])
    signed_contract, pending_contract = bundle.contracts.sort_by(&:message_object_id)
    signed_contract, pending_contract = pending_contract, signed_contract unless signed_contract.message_object == @message_object

    api = FakeApi.new(
      "contracts" => [
        { "id" => signed_contract.contract_identifier, "signed_document" => { "download_url" => "https://agp.example/signed" } },
        { "id" => pending_contract.contract_identifier }
      ]
    )

    bundle.sync!(api: api)

    assert signed_contract.reload.completed?
    assert pending_contract.reload.created?
    assert bundle.reload.created?
    assert @message_object.reload.is_signed?
    assert_equal "<signed />", @message_object.content
  end

  test "sync! completes bundle when all contracts are accepted" do
    bundle = created_bundle([@message_object])
    contract = bundle.contracts.first

    bundle.sync!(api: FakeApi.new("contracts" => [{ "id" => contract.contract_identifier, "signed_document" => { "download_url" => "https://agp.example/signed" } }]))

    assert contract.reload.completed?
    assert bundle.reload.completed?
  end

  test "sync! fails contracts unknown to AGP" do
    bundle = created_bundle([@message_object])

    bundle.sync!(api: FakeApi.new(nil))

    assert bundle.contracts.first.reload.failed?
    assert bundle.reload.failed?
  end

  test "polling interval grows with the age of the bundle" do
    bundle = created_bundle([@message_object])

    assert_equal Agp::Bundle::MIN_POLLING_INTERVAL.to_f, bundle.next_polling_in.to_f

    travel_to bundle.created_at + 1.hour do
      assert_in_delta 6.minutes.to_f, bundle.next_polling_in.to_f, 1
    end

    travel_to bundle.created_at + 2.days do
      assert_equal Agp::Bundle::MAX_POLLING_INTERVAL.to_f, bundle.next_polling_in.to_f
      assert_not bundle.polling_expired?
    end

    travel_to bundle.created_at + Agp::Bundle::POLLING_PERIOD + 1.minute do
      assert bundle.polling_expired?
    end
  end

  private

  def created_bundle(message_objects)
    Agp::Bundle.find_or_create_for!(tenant: @tenant, signer_user: @signer_user, message_objects: message_objects).tap do |bundle|
      bundle.update!(status: :created)
      bundle.contracts.each(&:created!)
    end
  end

  FailingUploadApi = Struct.new(:error) do
    def upload_bundle(*)
      raise error
    end
  end

  class FakeApi
    def initialize(remote_bundle)
      @remote_bundle = remote_bundle
    end

    def retrieve_bundle(_bundle_identifier)
      @remote_bundle
    end

    def download_signed_document(_signed_document)
      { filename: "signed.xml", content_type: "application/xml", content: "<signed />" }
    end
  end
end
