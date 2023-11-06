module Automation
  class MessageCreatedJob < ApplicationJob
    queue_as :default

    def perform(message)
      Automation.run_rules_for(message, :message_created)
    end
  end
end
