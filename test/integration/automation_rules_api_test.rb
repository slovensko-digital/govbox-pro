require "test_helper"

class AutomationRulesApiTest < ActionDispatch::IntegrationTest
  setup do
    @key_pair = OpenSSL::PKey::RSA.new File.read 'test/fixtures/tenant_test_cert.pem'
    @tenant = tenants(:ssd)
    @token = generate_api_token(sub: @tenant.id, key_pair: @key_pair)
  end

  test "creates a tagging rule and a new tag" do
    assert_difference -> { @tenant.automation_rules.count } => 1, -> { @tenant.tags.count } => 1 do
      post_rule(
        conditions: [{ type: "Automation::AttachmentContentContainsCondition", attr: "attachment", value: "2020123456" }],
        actions: [{ type: "Automation::AddMessageThreadTagAction", tag: "Invoice" }]
      )
    end

    assert_response :created
    json = response.parsed_body
    assert_equal "Tag invoices by VAT ID", json["name"]
    assert_equal [{ "type" => "Automation::AttachmentContentContainsCondition", "attr" => "attachment", "value" => "2020123456" }], json["conditions"]
    assert_equal "Invoice", json["actions"].sole["tag"]

    rule = @tenant.automation_rules.find(json["id"])
    assert_nil rule.user
    assert_equal @tenant.tags.find_by!(name: "Invoice"), rule.actions.sole.action_object
  end

  test "accepts every event that runs rules" do
    Automation::Rule::TRIGGER_EVENTS.each do |event|
      post_rule(trigger_event: event)

      assert_response :created, event
    end
  end

  test "reuses an existing tag" do
    tag = tags(:ssd_finance)

    assert_no_difference -> { Tag.count } do
      post_rule(actions: [{ type: "Automation::UnassignMessageThreadTagAction", tag: tag.name }])
    end

    assert_response :created
    assert_equal tag, @tenant.automation_rules.find(response.parsed_body["id"]).actions.sole.action_object
  end

  test "created rule tags a matching message" do
    post_rule(
      conditions: [{ type: "Automation::ContainsCondition", attr: "title", value: "faktúra" }],
      actions: [{ type: "Automation::AddMessageThreadTagAction", tag: "Invoice" }]
    )
    rule = @tenant.automation_rules.find(response.parsed_body["id"])
    message = messages(:ssd_main_general_one)
    message.update!(title: "Došla faktúra")

    rule.run!(message, :message_created)

    assert_includes message.thread.reload.tags.pluck(:name), "Invoice"
  end

  test "does not use a system tag with the given name" do
    signed_tag = tags(:ssd_signed)

    assert_no_difference -> { Automation::Rule.count }, -> { Tag.count } do
      post_rule(actions: [{ type: "Automation::AddMessageThreadTagAction", tag: signed_tag.name }])
    end

    assert_response :unprocessable_content
    assert_match "Actions action object is not a valid tag", response.parsed_body["message"]
  end

  test "creates a new tag only once when used by more actions" do
    assert_difference -> { @tenant.tags.count } => 1 do
      post_rule(actions: [
        { type: "Automation::AddMessageThreadTagAction", tag: "Invoice" },
        { type: "Automation::AddMessageThreadTagAction", tag: "Invoice" }
      ])
    end

    assert_response :created
    assert_equal 1, @tenant.automation_rules.find(response.parsed_body["id"]).actions.map(&:action_object_id).uniq.size
  end

  test "rejects an invalid rule without leaving a tag behind" do
    assert_no_difference -> { Automation::Rule.count }, -> { Tag.count } do
      post_rule(
        trigger_event: "nope",
        conditions: [{ type: "Automation::ContainsCondition", attr: "title", value: "(" }],
        actions: [{ type: "Automation::AddMessageThreadTagAction", tag: "Brand new tag" }]
      )
    end

    assert_response :unprocessable_content
    message = response.parsed_body["message"]
    assert_match "Trigger event is not included in the list", message
    assert_match "not a valid regular expression", message
  end

  test "rejects an unknown condition type" do
    assert_no_difference -> { Automation::Rule.count } do
      post_rule(conditions: [{ type: "Kernel", attr: "title", value: "a" }])
    end

    assert_response :unprocessable_content
  end

  test "rejects an unknown action type" do
    assert_no_difference -> { Automation::Rule.count }, -> { Tag.count } do
      post_rule(actions: [{ type: "Kernel", tag: "Brand new tag" }])
    end

    assert_response :unprocessable_content
  end

  test "creates a webhook action" do
    webhook = automation_webhooks(:one)

    post_rule(actions: [{ type: "Automation::FireWebhookAction", webhook_id: webhook.id }])

    assert_response :created
    assert_equal webhook.id, response.parsed_body["actions"].sole["webhook_id"]
    assert_equal webhook, @tenant.automation_rules.find(response.parsed_body["id"]).actions.sole.action_object
  end

  test "rejects a webhook of another tenant" do
    assert_no_difference -> { Automation::Rule.count } do
      post_rule(actions: [{ type: "Automation::FireWebhookAction", webhook_id: automation_webhooks(:solver).id }])
    end

    assert_response :unprocessable_content
    assert_match "Actions action object can't be blank", response.parsed_body["message"]
  end

  test "rejects a webhook action with a tag" do
    assert_no_difference -> { Automation::Rule.count } do
      post_rule(actions: [{ type: "Automation::FireWebhookAction", tag: "Invoice" }])
    end

    assert_response :unprocessable_content
    assert_match "Actions action object type is not included in the list", response.parsed_body["message"]
  end

  test "rejects a tag action without a tag" do
    assert_no_difference -> { Automation::Rule.count } do
      post_rule(actions: [{ type: "Automation::AddMessageThreadTagAction" }])
    end

    assert_response :unprocessable_content
    assert_match "Actions action object can't be blank", response.parsed_body["message"]
  end

  test "requires the automation_rule parameter" do
    post "/api/automation_rules", params: { token: @token }, as: :json

    assert_response :bad_request
  end

  test "lists, shows and deletes only own tenant rules" do
    rule = @tenant.automation_rules.create!(name: "r", trigger_event: "message_created")
    other = tenants(:solver).automation_rules.create!(name: "o", trigger_event: "message_created")

    get "/api/automation_rules", params: { token: @token }, as: :json
    assert_response :success
    ids = response.parsed_body.pluck("id")
    assert_includes ids, rule.id
    assert_not_includes ids, other.id

    get "/api/automation_rules/#{rule.id}", params: { token: @token }, as: :json
    assert_response :success
    assert_equal "r", response.parsed_body["name"]

    get "/api/automation_rules/#{other.id}", params: { token: @token }, as: :json
    assert_response :not_found

    delete "/api/automation_rules/#{other.id}", params: { token: @token }, as: :json
    assert_response :not_found

    delete "/api/automation_rules/#{rule.id}", params: { token: @token }, as: :json
    assert_response :no_content
    assert_not Automation::Rule.exists?(rule.id)
  end

  private

  def post_rule(**attributes)
    rule = { name: "Tag invoices by VAT ID", trigger_event: "message_created" }.merge(attributes)
    post "/api/automation_rules", params: { token: @token, automation_rule: rule }, as: :json
  end
end
