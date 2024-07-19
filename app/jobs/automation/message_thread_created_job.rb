module Automation
  class MessageThreadCreatedJob < ApplicationJob
    queue_as :automation

    def perform(message_thread)
      Automation.run_rules_for(message_thread, :message_thread_created)
    end
  end
end
