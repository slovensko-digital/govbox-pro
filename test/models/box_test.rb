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

  test "after_destroy callback destroys api_connection if Govbox::ApiConnection without any boxes" do
    box = boxes(:one)
    api_connection = box.api_connection

    box.destroy

    assert api_connection.destroyed?
  end

  test "after_destroy callback does not destroy api_connection if Govbox::ApiConnection with other boxes" do
    box = boxes(:four)
    api_connection = box.api_connection

    box.destroy

    assert_equal api_connection.destroyed?, false
  end

  test "after_destroy callback does not destroy api_connection if Govbox::ApiConnectionWithOboSupport" do
    box = boxes(:two)
    api_connection = box.api_connection

    box.destroy

    assert_equal api_connection.destroyed?, false
  end

  test "after_destroy callback does not destroy api_connection if SkApi::ApiConnectionWithOboSupport" do
    box = boxes(:three)
    api_connection = box.api_connection

    box.destroy

    assert_equal api_connection.destroyed?, false
  end
end
