require "test_helper"

class BoxTest < ActiveSupport::TestCase
  test "should not be valid if obo value present in settings when api_connection is a Govbox::ApiConnection" do
    box = boxes(:one)
    assert box.valid?

    box.settings = {
      "obo": SecureRandom.uuid
    }

    assert_equal box.valid?, false
  end

  test "should not be valid if obo value present in Govbox::ApiConnectionWithOboSupport" do
    box = boxes(:two)
    assert box.valid?

    box.api_connection.update(obo: SecureRandom.uuid)

    assert_equal box.valid?, false
  end

  test "should not be valid if obo value present in SkApi::ApiConnectionWithOboSupport" do
    box = boxes(:three)
    assert box.valid?

    box.api_connection.update(obo: SecureRandom.uuid)

    assert_equal box.valid?, false
  end
end
