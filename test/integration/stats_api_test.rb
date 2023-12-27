require "test_helper"

class StatsApiTest < ActionDispatch::IntegrationTest
  test "can read number of users" do
    tenant = tenants(:solver)

    get "/api/site_admin/stats/tenants/#{tenant.id}/users_count", params: { token: generate_api_token }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response["users_count"].positive?
  end

  test "can read number of messages per period" do
    tenant = tenants(:solver)

    get "/api/site_admin/stats/tenants/#{tenant.id}/messages_per_period",
        params: { from: Time.zone.now - 100.days, to: Time.zone.now, token: generate_api_token }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response["messages_per_period"].positive?
  end

  test "can not read period stats without from/to" do
    tenant = tenants(:solver)

    get "/api/site_admin/stats/tenants/#{tenant.id}/messages_per_period",
        params: { token: generate_api_token }, as: :json

    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_match "From je povinná položka", json_response["message"]
  end

  test "can read number of messages" do
    tenant = tenants(:solver)

    get "/api/site_admin/stats/tenants/#{tenant.id}/messages_count", params: { token: generate_api_token }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response["messages_count"].positive?
  end
end
