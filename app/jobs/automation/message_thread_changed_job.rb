module Automation
  class MessageThreadChangedJob < ApplicationJob
    queue_as :automation

    def perform(message)
      Automation.run_rules_for(message, :message_thread_changed)
    end
  end
end
