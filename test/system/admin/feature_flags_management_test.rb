require "application_system_test_case"

class FeatureFlagsManagementTest < ApplicationSystemTestCase
  setup do
    sign_in_as(:admin)
    visit root_path
    click_link "Nastavenia"
    click_link "Aktivácia rozšírení"
  end

  test "admin can enable and disable a feature" do
    available_features = users(:admin).tenant.list_available_features
    enabled = users(:admin).tenant.feature_enabled?(available_features[0])
    click_button available_features[0]
    assert_button available_features[0]
    users(:admin).tenant.reload
    assert_not_equal enabled, users(:admin).tenant.feature_enabled?(available_features[0])
  end
end
