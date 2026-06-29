require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "before_save callback normalizes saml_identifier attribute" do
    user = User.find_or_create_by(tenant: Tenant.first, name: 'New user', email: 'new_user@slovensko.digital', saml_identifier: '')

    assert_nil user.saml_identifier
  end
end
