module Automate
  def run_rules_for(thing, event, params: {})
    thing.tenant.automation_rules.where(trigger_event: event).each do |rule|
      rule.run!(thing, event, params: params)
    end
  end
end
