require "test_helper"

class Agp::BundlesControllerTest < ActionController::TestCase
  setup do
    @controller = Agp::BundlesController.new
    @tenant = tenants(:ssd)
    @user = users(:ssd_signer)
    @message_object_one = message_objects(:ssd_main_general_draft_two_form)
    @message_object_two = message_objects(:ssd_main_general_draft_three_form)
    @bundle = Agp::Bundle.create!(tenant: @tenant, bundle_identifier: SecureRandom.uuid, status: :created)
    @contract_one = create_contract_for(@message_object_one)
    @contract_two = create_contract_for(@message_object_two)

    @tenant.update!(
      feature_flags: (@tenant.feature_flags + ["autogram_portal"]).uniq,
      settings_agp_api_url: "https://agp.example.test",
      settings_agp_api_token_private_key: OpenSSL::PKey::RSA.generate(2048).to_pem,
      settings_agp_sub: "govbox-test"
    )

    Current.tenant = @tenant
    Current.user = @user
    session[:tenant_id] = @tenant.id
    session[:user_id] = @user.id
    session[:login_expires_at] = Time.current + 1.day
  end

  teardown do
    Current.reset
  end

  test "show json reports pending bundle sync while some contracts are unsigned" do
    get :show, params: { id: @bundle.id, format: :json }

    assert_response :success

    payload = JSON.parse(response.body)
    assert_equal 2, payload["total_contracts_count"]
    assert_equal 0, payload["signed_contracts_count"]
    assert_equal false, payload["fully_synced"]
  end

  test "show json reports bundle synced when all message objects are signed" do
    @message_object_one.update!(is_signed: true)
    @message_object_two.update!(is_signed: true)

    get :show, params: { id: @bundle.id, format: :json }

    assert_response :success

    payload = JSON.parse(response.body)
    assert_equal 2, payload["total_contracts_count"]
    assert_equal 2, payload["signed_contracts_count"]
    assert_equal true, payload["fully_synced"]
  end

  test "new autostarts agp bundle preparation in modal" do
    get :new, params: { object_ids: [@message_object_one.id] }

    assert_response :success
    assert_includes response.body, "Pripravujeme podpisovanie cez Autogram Portal."
    assert_includes response.body, "agp-bundle-autostart-form"
    assert_not_includes response.body, "Spustiť podpisovanie"
  end

  test "create falls back to direct signing when agp initialization fails" do
    fallback_user = users(:basic)
    fallback_message_draft = messages(:ssd_main_draft)
    fallback_message_object = message_objects(:ssd_main_draft_form)
    failing_job = Struct.new(:error) do
      def perform(*)
        raise error
      end
    end.new(StandardError.new("boom"))

    Current.user = fallback_user
    session[:user_id] = fallback_user.id
    session[:tenant_id] = fallback_user.tenant_id

    bundle = Agp::Bundle.find_or_initialize_from_message_objects(@tenant, [fallback_message_object], signer_user: fallback_user)

    Agp::UploadBundleJob.stub(:new, failing_job) do
      post :create, params: {
        message_draft_id: fallback_message_draft.id,
        object_ids: [fallback_message_object.id],
        agp_bundle: {
          bundle_identifier: bundle.bundle_identifier,
          contracts_attributes: {
            "0" => {
              contract_identifier: bundle.contracts.first.contract_identifier,
              message_object_id: fallback_message_object.id,
              message_object_updated_at: fallback_message_object.updated_at
            }
          }
        }
      }
    end

    assert_response :success
    assert_includes response.body, 'data-controller="autogram"'
    assert_includes response.body, message_draft_signing_path(fallback_message_draft)
  end

  private

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
