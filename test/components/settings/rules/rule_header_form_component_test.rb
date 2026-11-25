# frozen_string_literal: true

require "test_helper"

class Settings::Rules::RuleHeaderFormComponentTest < ViewComponent::TestCase
  test "keeps message_updated selected when editing a rule triggered by it" do
    rule = Automation::Rule.new(name: "Zmena potvrdenky", trigger_event: "message_updated")
    form = ActionView::Helpers::FormBuilder.new(:automation_rule, rule, vc_test_controller.view_context, {})

    render_inline(Settings::Rules::RuleHeaderFormComponent.new(form: form))

    assert_selector "select option[selected][value='message_updated']", text: "Upravená správa"
  end
end
