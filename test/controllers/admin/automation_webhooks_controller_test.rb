require "test_helper"

class Admin::AutomationWebhooksControllerTest < ActionController::TestCase
  setup do
    @controller = Admin::AutomationWebhooksController.new
    @tenant = tenants(:ssd)
    @admin = users(:admin)

    Current.tenant = @tenant
    Current.user = @admin
    session[:tenant_id] = @tenant.id
    session[:user_id] = @admin.id
    session[:login_expires_at] = Time.now + 1.day
  end

  teardown do
    Current.reset
  end

  test "create renders the form again when the url is not a public https url" do
    assert_no_difference -> { Automation::Webhook.count } do
      post :create, params: { tenant_id: @tenant.id, automation_webhook: { name: "Webhook", url: "http://example.com/hook" } }
    end

    assert_response :unprocessable_content
  end

  test "create saves the webhook when the url is a public https url" do
    Resolv.stub(:getaddresses, ["93.184.216.34"]) do
      assert_difference -> { Automation::Webhook.count }, 1 do
        post :create, params: { tenant_id: @tenant.id, automation_webhook: { name: "Webhook", url: "https://example.com/hook" } }
      end
    end

    assert_redirected_to admin_tenant_automation_webhooks_url(@tenant)
  end
end
