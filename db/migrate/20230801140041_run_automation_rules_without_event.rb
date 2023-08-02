class RunAutomationRulesWithoutEvent < ActiveRecord::Migration[7.0]
  def up
    Message.find_each do |message|
      Automation::MessageCreatedJob.perform_later(message)
    end
  end
end
