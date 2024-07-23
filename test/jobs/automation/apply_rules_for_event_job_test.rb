require "test_helper"

class Automation::ApplyRulesForEventJobTest < ActiveJob::TestCase
  test "should call thing.automation_rules_for_event event" do
    event = :event
    thing = Minitest::Mock.new
    rule = Minitest::Mock.new
    rule.expect :run!, nil, [thing, event]
    thing.expect :automation_rules_for_event, [rule], [event]

    Automation::ApplyRulesForEventJob.new.perform(event, thing)
    assert_mock thing
    assert_mock rule
  end
end
