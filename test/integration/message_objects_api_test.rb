require "test_helper"

class MessageObjectsApiTest < ActionDispatch::IntegrationTest
  setup do
    @key_pair = OpenSSL::PKey::RSA.new File.read 'test/fixtures/tenant_test_cert.pem'
    @tenant = tenants(:ssd)
  end

  test "can get PDF visualization" do
    message_object = message_objects(:ssd_main_general_two_form)

    get "/api/message_objects/#{message_object.id}/pdf", params: { token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }, as: :json

    assert_response :success
    assert_equal "application/pdf", response.headers["content-type"]
    assert_equal "download; filename=\"MyString.pdf\"; filename*=UTF-8''MyString.pdf", response.headers["content-disposition"]
    assert_equal "%PDF-1.4", response.body.first(8)
  end

  test "responses with not found unless object downloadable as PDF" do
    message_object = message_objects(:ssd_main_general_one_attachment)

    get "/api/message_objects/#{message_object.id}/pdf", params: { token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }, as: :json

    assert_response :not_found
  end

  test "tells an API client whether asking for the PDF again can help" do
    get_fs_form_pdf(answer: ->(*, **) { raise Fs::PdfVisualizationUnavailable, "busy" })
    assert_response :service_unavailable
    assert_equal "30", response.headers["Retry-After"]

    get_fs_form_pdf(answer: ->(*, **) { raise Fs::PdfVisualizationTooLarge, "596 kB" })
    assert_response :content_too_large
  end

  private

  def get_fs_form_pdf(answer:)
    tenant = tenants(:accountants)
    message_object = message_objects(:fs_accountants_dphv21_form)
    message_object.message.form.update!(pdf_supported: true)
    tenant.enable_feature(:fs_pdf_visualization, force: true) unless tenant.feature_enabled?(:fs_pdf_visualization)
    fs_api = Object.new
    fs_api.define_singleton_method(:pdf_visualization, &answer)

    FsEnvironment.fs_client.stub(:api, ->(**) { fs_api }) do
      get "/api/message_objects/#{message_object.id}/pdf", params: { token: generate_api_token(sub: tenant.id, key_pair: @key_pair) }, as: :json
    end
  end
end
