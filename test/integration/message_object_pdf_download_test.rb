require "test_helper"
require "helpers/auth_helper"

class MessageObjectPdfDownloadTest < ActionDispatch::IntegrationTest
  include AuthHelper

  setup do
    @form = message_objects(:fs_accountants_draft_uzmujv14_form2)
    @form.message.form.update!(pdf_supported: true)
    @form.tenant.enable_feature(:fs_pdf_visualization, force: true)

    mock_omni_auth_with_user(:accountants_basic)
    get "/auth/google_oauth2/callback"
  end

  test "a busy FS API asks the user to try again shortly" do
    with_fs_api(->(*, **) { raise Fs::PdfVisualizationUnavailable, "busy" }) do
      get download_pdf_message_message_object_path(@form.message, @form)
    end

    assert_redirected_to message_thread_path(@form.message.thread)
    assert_match(/skúste to o chvíľu znova/, flash[:alert])
  end

  test "a form the FS API refuses does not promise that trying again helps" do
    with_fs_api(->(*, **) { nil }) do
      get download_pdf_message_message_object_path(@form.message, @form)
    end

    assert_equal "Obsah nie je možné stiahnuť.", flash[:alert]
  end

  test "a form too large to visualize points the user to its original" do
    with_fs_api(->(*, **) { raise Fs::PdfVisualizationTooLarge, "596 kB" }) do
      get download_pdf_message_message_object_path(@form.message, @form)
    end

    assert_match(/príliš veľký/, flash[:alert])
  end

  private

  def with_fs_api(answer, &block)
    fs_api = Object.new
    fs_api.define_singleton_method(:pdf_visualization, &answer)
    FsEnvironment.fs_client.stub(:api, ->(**) { fs_api }, &block)
  end
end
