require "test_helper"

class Agp::BundlesControllerTest < ActionController::TestCase
  include ActiveJob::TestHelper

  setup do
    @controller = Agp::BundlesController.new
    @tenant = tenants(:ssd)
    @user = users(:ssd_signer)
    @message_object_one = message_objects(:ssd_main_general_draft_two_form)
    @message_object_two = message_objects(:ssd_main_general_draft_three_form)
    @bundle = Agp::Bundle.create!(tenant: @tenant, status: :created)
    @contract_one = create_contract_for(@message_object_one)
    @contract_two = create_contract_for(@message_object_two)

    @tenant.update!(
      feature_flags: (@tenant.feature_flags + ["autogram_portal"]).uniq,
      settings_agp_api_url: "https://agp.example.test",
      settings_agp_api_token_private_key: OpenSSL::PKey::RSA.generate(2048).to_pem,
      settings_agp_sub: "govbox-test"
    )

    sign_in(@user)
  end

  teardown do
    Current.reset
  end

  test "show renders agp signing iframe controller" do
    get :show, params: { id: @bundle.id }

    assert_response :success
    assert_select "[data-controller='agp-signing'][data-agp-signing-agp-url-value='https://agp.example.test'][data-agp-signing-bundle-id-value='#{@bundle.bundle_identifier}']"
    assert_select "[data-agp-signing-sync-url-value='#{sync_agp_bundle_path(@bundle)}']"
    # inline scripts in the modal would be blocked by the content security policy
    assert_select "turbo-frame#modal script", count: 0
  end

  test "show is denied to other users of the tenant" do
    sign_in(users(:ssd_signer2))

    get :show, params: { id: @bundle.id }

    assert_redirected_to root_path
  end

  test "show json reports pending bundle sync while some contracts are not accepted" do
    @contract_one.completed!

    get :show, params: { id: @bundle.id, format: :json }

    assert_response :success

    payload = JSON.parse(response.body)
    assert_equal "created", payload["status"]
    assert_equal 2, payload["total_contracts_count"]
    assert_equal 1, payload["completed_contracts_count"]
    assert_equal false, payload["finished"]
  end

  test "show json reports finished bundle" do
    @contract_one.completed!
    @contract_two.completed!
    @bundle.finish_if_done!

    get :show, params: { id: @bundle.id, format: :json }

    payload = JSON.parse(response.body)
    assert_equal "completed", payload["status"]
    assert_equal 2, payload["completed_contracts_count"]
    assert_equal true, payload["finished"]
  end

  test "sync enqueues bundle sync" do
    assert_enqueued_with(job: Agp::SyncBundleJob, args: [@bundle]) do
      post :sync, params: { id: @bundle.id }
    end

    assert_response :accepted
  end

  test "new autostarts agp bundle preparation in modal" do
    get :new, params: { object_ids: [@message_object_one.id] }

    assert_response :success
    assert_includes response.body, "Pripravujeme podpisovanie cez Autogram Portal."
    assert_select "form#agp-bundle-autostart-form[data-controller='autosubmit-form'] input[name='object_ids[]'][value='#{@message_object_one.id}']"
  end

  test "create uploads bundle built from accessible message objects and redirects to it" do
    api = FakeApi.new

    with_agp_api(api) do
      assert_difference -> { Agp::Bundle.count }, 1 do
        post :create, params: { object_ids: [@message_object_one.id] }
      end
    end

    bundle = Agp::Bundle.order(:id).last
    assert_redirected_to agp_bundle_path(bundle)
    assert bundle.created?
    assert_equal [@message_object_one], bundle.contracts.map(&:message_object)
    assert_equal [@user], bundle.contracts.map(&:signer_user)
    assert bundle.contracts.all?(&:created?)
    assert_equal [[bundle, "http://test.host/agp/webhooks"]], api.uploads
    assert_enqueued_with(job: Agp::SyncBundleJob, args: [bundle, { poll: true }])
  end

  test "create reuses recent bundle for unchanged documents" do
    with_agp_api(FakeApi.new) do
      post :create, params: { object_ids: [@message_object_one.id] }
      first_bundle = Agp::Bundle.order(:id).last

      assert_no_difference -> { Agp::Bundle.count } do
        post :create, params: { object_ids: [@message_object_one.id] }
      end

      assert_redirected_to agp_bundle_path(first_bundle)
    end
  end

  test "create ignores message objects outside of the user's scope" do
    foreign_message_object = message_objects(:fs_accountants_draft_form)

    with_agp_api(FakeApi.new) do
      assert_no_difference -> { Agp::Bundle.count } do
        post :create, params: { object_ids: [foreign_message_object.id] }
      end
    end

    assert_response :see_other
    assert_equal "Vo vybraných vláknach sa nenašli žiadne dokumenty so žiadosťou na podpis", flash[:alert]
  end

  test "create falls back to direct signing when agp initialization fails" do
    fallback_message_draft = messages(:ssd_main_draft)
    fallback_message_object = message_objects(:ssd_main_draft_form)

    sign_in(users(:basic))

    with_agp_api(FakeApi.new(error: Agp::Api::Error.new("boom"))) do
      post :create, params: {
        message_draft_id: fallback_message_draft.id,
        object_ids: [fallback_message_object.id]
      }
    end

    assert_response :success
    assert_includes response.body, 'data-controller="autogram"'
    assert_includes response.body, message_draft_signing_path(fallback_message_draft)
    assert Agp::Bundle.order(:id).last.init_failed?
  end

  test "returns not found when tenant has autogram portal disabled" do
    @tenant.update!(feature_flags: @tenant.feature_flags - ["autogram_portal"])

    get :show, params: { id: @bundle.id }

    assert_response :not_found
  end

  private

  class FakeApi
    attr_reader :uploads

    def initialize(error: nil)
      @error = error
      @uploads = []
    end

    def upload_bundle(bundle, webhook_url:)
      raise @error if @error

      @uploads << [bundle, webhook_url]
    end
  end

  def with_agp_api(api, &block)
    Agp.stub(:api_for, api, &block)
  end

  def sign_in(user)
    Current.tenant = user.tenant
    Current.user = user
    session[:tenant_id] = user.tenant_id
    session[:user_id] = user.id
    session[:login_expires_at] = Time.current + 1.day
  end

  def create_contract_for(message_object)
    Agp::Contract.create!(
      bundle: @bundle,
      message_object: message_object,
      message_object_updated_at: message_object.updated_at,
      status: :created,
      signer_user: @user
    )
  end
end
