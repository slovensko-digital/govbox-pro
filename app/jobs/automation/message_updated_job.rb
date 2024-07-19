module Automation
  class MessageUpdatedJob < ApplicationJob
    queue_as :automation

    def perform(message)
      Automation.run_rules_for(message, :message_updated)
    end
  end
end
