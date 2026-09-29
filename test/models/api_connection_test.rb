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

  test "api_token_private_key is encrypted at rest" do
    api_connection = api_connections(:govbox_api_api_connection1)

    raw_value = ApiConnection.connection.select_value(
      ApiConnection.unscoped.where(id: api_connection.id).select(:api_token_private_key).to_sql
    )

    assert_not_includes raw_value, "BEGIN PRIVATE KEY"
    assert_includes api_connection.api_token_private_key, "BEGIN PRIVATE KEY"
    assert OpenSSL::PKey::RSA.new(api_connection.api_token_private_key)
  end

  test "encrypting the base class does not leak encrypted attributes across STI subclasses" do
    assert_equal Set[:api_token_private_key], ApiConnection.encrypted_attributes
    assert_equal Set[:api_token_private_key], Govbox::ApiConnection.encrypted_attributes
    assert_equal Set[:api_token_private_key, :settings], Fs::ApiConnection.encrypted_attributes
  end
end
