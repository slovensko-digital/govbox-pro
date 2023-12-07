require "test_helper"

class HealthCheckTest < ActionDispatch::IntegrationTest
  test "healthcheck responds with 200 OK" do
    get '/health/'

    assert_response :success
  end

  test "failing jobs healthcheck responds with 200 OK" do
    get '/health/jobs/failing'

    assert_response :success
  end

  test "stuck jobs healthcheck responds with 200 OK" do
    get '/health/jobs/stuck'

    assert_response :success
  end
end
