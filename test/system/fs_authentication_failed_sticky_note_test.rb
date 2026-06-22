require "application_system_test_case"

class FsAuthenticationFailedStickyNoteTest < ApplicationSystemTestCase
  setup do
    @api_connection = api_connections(:fs_api_connection1)
    @api_connection.update!(custom_name: "FS test prepojenie")
    sign_in_as(:accountants_basic)
  end

  test "admin sees sticky note after fs authentication failure" do
    visit message_threads_path
    save_screenshot "tmp/fs-auth-sticky-01-before-failure.png"

    first_box = @api_connection.boxes.where(type: "Fs::Box").active.syncable.order(:id).first
    expected_api_connection = @api_connection
    fs_client = Class.new do
      define_method(:api) do |api_connection:, box:|
        raise "unexpected api connection" unless api_connection == expected_api_connection
        raise "unexpected box" unless box == first_box

        Class.new do
          def fetch_received_messages(**)
            raise Fs::AuthenticationError, "bad credentials"
          end
        end.new
      end
    end.new

    FsEnvironment.stub :fs_client, fs_client do
      Fs::SyncApiConnectionJob.perform_now(@api_connection)
    end

    visit message_threads_path
    assert_text "Prihlásenie na finančnú správu zlyhalo"
    assert_text "FS test prepojenie"
    save_screenshot "tmp/fs-auth-sticky-02-after-failure.png"

    click_on "FS test prepojenie"
    assert_text "Úprava prepojenia s FS"
    save_screenshot "tmp/fs-auth-sticky-03-edit-connection-modal.png"
  end
end
