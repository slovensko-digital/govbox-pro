require "test_helper"

class BoxTest < ActiveSupport::TestCase
  test "should not be valid if obo value present in settings when api_connection is a Govbox::ApiConnection" do
    box = boxes(:ssd_main)
    assert box.valid?

    box.settings = {
      "obo": SecureRandom.uuid
    }

    assert_equal box.valid?, false
  end

  test "should not be valid if obo value present in Govbox::ApiConnectionWithOboSupport" do
    box = boxes(:ssd_other)
    assert box.valid?

    box.api_connection.update(obo: SecureRandom.uuid)

    assert_equal box.valid?, false
  end
end
