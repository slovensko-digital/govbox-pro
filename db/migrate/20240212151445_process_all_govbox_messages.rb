class ProcessAllGovboxMessages < ActiveRecord::Migration[7.1]
  def change
    Govbox::Message.find_each { |govbox_message| Govbox::ProcessMessageJob.perform_later(govbox_message) }
  end
end
