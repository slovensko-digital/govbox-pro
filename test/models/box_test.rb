require "test_helper"

class BoxTest < ActiveSupport::TestCase
  test "should not be valid if not valid Govbox::ApiConnection settings" do
    box = boxes(:one)
    assert box.valid?

    box.settings = {
      "obo": SecureRandom.uuid
    }

    assert_equal box.valid?, false
  end

  test "should not be valid if not valid Govbox::ApiConnectionWithOboSupport settings" do
    box = boxes(:two)
    assert box.valid?

    box.settings = {
      "obo": SecureRandom.uuid
    }

    assert_equal box.valid?, false
  end

  test "should not be valid if not valid SkApi::ApiConnectionWithOboSupport settings" do
    box = boxes(:three)
    assert box.valid?

    box.settings = {
      "obo": SecureRandom.uuid
    }

    assert_equal box.valid?, false
  end
end
