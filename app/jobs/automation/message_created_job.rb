module Automation
  class MessageCreatedJob < ApplicationJob
    def perform(message)
      Automation.run_rules_for(message, :message_created)
    end
  end
end
