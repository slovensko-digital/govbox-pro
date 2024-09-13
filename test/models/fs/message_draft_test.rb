# frozen_string_literal: true

require "test_helper"

class Fs::MessageDraftTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionDispatch::TestProcess::FixtureFile

  test "create_and_validate_with_fs_form method schedules Fs::ValidateMessageDraftJob" do
    fs_api = Minitest::Mock.new
    fs_api.expect :parse_form, {
      "subject" => "1122334455",
      "form_identifier" => "3055_781"
    },
    [file_fixture("fs/dic1122334455_fs3055_781__sprava_dani_2023.xml").read]

  FsEnvironment.fs_client.stub :api, fs_api do
    assert_enqueued_with(job: Fs::ValidateMessageDraftJob) do
        Fs::MessageDraft.create_and_validate_with_fs_form(form_files: [fixture_file_upload("fs/dic1122334455_fs3055_781__sprava_dani_2023.xml", "application/xml")], author: users(:accountants_basic))
      end
    end
  end
end
