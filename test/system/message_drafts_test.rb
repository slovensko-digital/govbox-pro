require "application_system_test_case"

class MessageDraftsTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  setup do
    sign_in_as(:basic)
  end

  test "user can create message draft as reply on replyable message" do
  end
end
