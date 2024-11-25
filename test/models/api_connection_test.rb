# == Schema Information
#
# Table name: api_connections
#
#  id                    :bigint           not null, primary key
#  api_token_private_key :string           not null
#  obo                   :uuid
#  settings              :jsonb
#  sub                   :string           not null
#  type                  :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  tenant_id             :bigint
#
require "test_helper"

class ApiConnectionTest < ActiveSupport::TestCase
  test "Govbox::ApiConnection.box_obo raises error if invalid box" do
    box = boxes(:google_box_with_govbox_api_connection)

    box.settings = {
      "obo": SecureRandom.uuid
    }

    assert_raises(Exception) { box.api_connection.box_obo(box) }
  end

  test "Govbox::ApiConnectionWithOboSupport.box_obo raises error if invalid box" do
    box = boxes(:google_box_with_govbox_api_connection_with_obo_support)

    box.api_connection.update(obo: SecureRandom.uuid)

    assert_raises(Exception) { box.api_connection.box_obo(box) }
  end

  test "SkApi::ApiConnectionWithOboSupport.box_obo raises error if invalid box" do
    box = boxes(:google_box_with_sk_api_api_connection_with_obo_support)

    box.api_connection.update(obo: SecureRandom.uuid)

    assert_raises(Exception) { box.api_connection.box_obo(box) }
  end
end
