require "test_helper"

class Agp::SyncBundleJobTest < ActiveJob::TestCase
  setup do
    @bundle = Agp::Bundle.find_or_create_for!(tenant: tenants(:ssd), signer_user: users(:ssd_signer), message_objects: [message_objects(:ssd_main_general_draft_two_form)])
    @bundle.update!(status: :created)
    @bundle.contracts.each(&:created!)
  end

  test "polling reschedules itself while the bundle is not signed" do
    api = FakeApi.new("contracts" => [{ "id" => @bundle.contracts.first.contract_identifier }])

    Agp.stub(:api_for, api) do
      assert_enqueued_with(job: Agp::SyncBundleJob, args: [@bundle, { poll: true }]) do
        Agp::SyncBundleJob.perform_now(@bundle, poll: true)
      end
    end

    assert_equal 1, api.retrieved
  end

  test "polling stops once the bundle is signed" do
    contract = @bundle.contracts.first
    api = FakeApi.new("contracts" => [{ "id" => contract.contract_identifier, "signed_document" => { "download_url" => "https://agp.example/signed" } }])

    Agp.stub(:api_for, api) do
      assert_no_enqueued_jobs only: Agp::SyncBundleJob do
        Agp::SyncBundleJob.perform_now(@bundle, poll: true)
      end
    end

    assert @bundle.reload.completed?
  end

  test "one-off sync does not reschedule" do
    api = FakeApi.new("contracts" => [{ "id" => @bundle.contracts.first.contract_identifier }])

    Agp.stub(:api_for, api) do
      assert_no_enqueued_jobs only: Agp::SyncBundleJob do
        Agp::SyncBundleJob.perform_now(@bundle)
      end
    end

    assert_equal 1, api.retrieved
  end

  test "polling expires pending contracts after the polling period" do
    api = FakeApi.new(nil)

    travel_to @bundle.created_at + Agp::Bundle::POLLING_PERIOD + 1.minute do
      Agp.stub(:api_for, api) do
        assert_no_enqueued_jobs only: Agp::SyncBundleJob do
          Agp::SyncBundleJob.perform_now(@bundle, poll: true)
        end
      end
    end

    assert_equal 0, api.retrieved
    assert @bundle.reload.failed?
    assert @bundle.contracts.first.reload.failed?
  end

  test "skips bundles that are not pending" do
    @bundle.update!(status: :completed)
    api = FakeApi.new(nil)

    Agp.stub(:api_for, api) do
      Agp::SyncBundleJob.perform_now(@bundle, poll: true)
    end

    assert_equal 0, api.retrieved
  end

  class FakeApi
    attr_reader :retrieved

    def initialize(remote_bundle)
      @remote_bundle = remote_bundle
      @retrieved = 0
    end

    def retrieve_bundle(_bundle_identifier)
      @retrieved += 1
      @remote_bundle
    end

    def download_signed_document(_signed_document)
      { filename: "signed.xml", content_type: "application/xml", content: "<signed />" }
    end
  end
end
