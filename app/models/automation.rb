module Automation
  def self.table_name_prefix
    'automation_'
  end

  def self.run_rules_for(thing, event, params: {})
    thing.automation_rules_for_event(event).each { |rule| rule.run!(thing, event) }
  end
end
