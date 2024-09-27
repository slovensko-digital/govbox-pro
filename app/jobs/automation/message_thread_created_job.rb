module Automation
  class MessageThreadCreatedJob < ApplicationJob
    def perform(message_thread)
      Automation.run_rules_for(message_thread, :message_thread_created)
    end
  end
end
