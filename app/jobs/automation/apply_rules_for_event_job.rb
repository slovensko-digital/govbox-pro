module Automation
  class ApplyRulesForEventJob < ApplicationJob
    queue_as :automation

    def perform(event, thing)
      Automation.run_rules_for(thing, event)
    end
  end
end
