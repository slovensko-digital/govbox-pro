module Automation
  class MessageCreatedJob < ApplicationJob
    queue_as :default

    include GoodJob::ActiveJobExtensions::Batches

    def perform(message)
      Automation.run_rules_for(message, :message_created)
    end
  end
end
