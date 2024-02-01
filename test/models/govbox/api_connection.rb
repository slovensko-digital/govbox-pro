require "test_helper"

class Govbox::ApiConnectionTest < ActiveSupport::TestCase
  test "should not be valid if tenant is set" do
    api_connection = api_connections(:govbox_api_api_connection1)
    api_connection.update(tenant: Tenant.first)

    assert_not api_connection.valid?
  end
end