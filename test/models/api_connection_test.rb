require "test_helper"

class ApiConnectionTest < ActiveSupport::TestCase
  test "Govbox::ApiConnection.box_obo raises error if invalid box" do
    box = boxes(:ssd_main)

    box.settings = {
      "obo": SecureRandom.uuid
    }

    assert_raises(Exception) { box.api_connection.box_obo(box) }
  end

  test "Govbox::ApiConnectionWithOboSupport.box_obo raises error if invalid box" do
    box = boxes(:ssd_other)

    box.api_connection.update(obo: SecureRandom.uuid)

    assert_raises(Exception) { box.api_connection.box_obo(box) }
  end
end
