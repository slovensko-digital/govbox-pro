require "test_helper"

class ImportmapCspTest < ActionDispatch::IntegrationTest
  test "login import map and module entrypoint are permitted by CSP" do
    get auth_path

    assert_response :success
    policy = response.headers.fetch("Content-Security-Policy")
    assert_select 'script[type="importmap"], script[type="module"]', count: 2 do |scripts|
      scripts.each do |script|
        nonce = script["nonce"]
        assert nonce.present?
        assert_includes policy, "'nonce-#{nonce}'"
      end
    end
  end
end
