require 'json'

module Govbox
  class ProcessMessageJob < ApplicationJob
    queue_as :default

    def perform(govbox_message)
      ActiveRecord::Base.transaction do
        Govbox::Message.create_message_with_thread!(govbox_message)
      end
    end
  end
end

