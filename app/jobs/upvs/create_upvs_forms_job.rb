module Upvs
  class CreateUpvsFormsJob < ApplicationJob
    queue_as :default

    def perform
      MessageObject.find_each do |message_object|
        message_object.find_or_create_form
      end
    end
  end
end
