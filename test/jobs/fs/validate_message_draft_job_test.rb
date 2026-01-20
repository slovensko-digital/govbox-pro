require "test_helper"

class Fs::ValidateMessageDraftJobTest < ActiveJob::TestCase
test "message is marked as invalid & FS API returns errors" do
    outbox_message = messages(:fs_accountants_outbox)

    fs_api = Minitest::Mock.new
    fs_api.expect :post_validation, {
      :status => 422,
      :body => {
      }
    },
    [ outbox_message.form.identifier, Base64.strict_encode64(outbox_message.form_object.content) ]

    FsEnvironment.fs_client.stub :api, fs_api do
      assert_raise do
        subject.new.perform(outbox_message)

        assert_equal outbox_message.metadata[:status] == 'invalid'
      end
    end
  end
end
