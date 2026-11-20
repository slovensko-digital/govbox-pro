require "test_helper"

class AutomationRulesApiTest < ActionDispatch::IntegrationTest
  setup do
    @key_pair = OpenSSL::PKey::RSA.new File.read 'test/fixtures/tenant_test_cert.pem'
    @tenant = tenants(:ssd)
    @token = generate_api_token(sub: @tenant.id, key_pair: @key_pair)
  end

  test "creates a tagging rule with a new tag" do
    assert_difference -> { @tenant.automation_rules.count } => 1 do
      post "/api/automation_rules", params: {
        token: @token,
        automation_rule: {
          name: "Rule by VAT ID",
          trigger_event: "message_created",
          conditions: [{ type: "Automation::AttachmentContentContainsCondition", attr: "attachment", value: "2020123456" }],
          actions: [{ type: "Automation::AddMessageThreadTagAction", tag: "Client tag" }]
        }
      }, as: :json
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "Rule by VAT ID", json["name"]
    assert_equal "Client tag", json["actions"].first["tag"]
    assert_equal "Client tag", @tenant.automation_rules.find(json["id"]).actions.first.action_object.name
  end

  test "rejects unknown condition type" do
    assert_no_difference -> { Automation::Rule.count } do
      post "/api/automation_rules", params: {
        token: @token,
        automation_rule: {
          name: "x", trigger_event: "message_created",
          conditions: [{ type: "Kernel", attr: "title", value: "a" }],
          actions: [{ type: "Automation::AddMessageThreadTagAction", tag: "A" }]
        }
      }, as: :json
    end

    assert_response :unprocessable_content
  end

  test "rejects unknown trigger event" do
    post "/api/automation_rules", params: {
      token: @token,
      automation_rule: { name: "x", trigger_event: "nope", actions: [{ type: "Automation::AddMessageThreadTagAction", tag: "A" }] }
    }, as: :json

    assert_response :unprocessable_content
  end

  test "lists and deletes only own tenant rules" do
    rule = @tenant.automation_rules.create!(name: "r", trigger_event: "message_created")
    other = tenants(:solver).automation_rules.create!(name: "o", trigger_event: "message_created")

    get "/api/automation_rules", params: { token: @token }, as: :json
    assert_response :success
    ids = JSON.parse(response.body).pluck("id")
    assert_includes ids, rule.id
    assert_not_includes ids, other.id

    delete "/api/automation_rules/#{other.id}", params: { token: @token }, as: :json
    assert_response :not_found

    delete "/api/automation_rules/#{rule.id}", params: { token: @token }, as: :json
    assert_response :no_content
    assert_not Automation::Rule.exists?(rule.id)
  end
end
