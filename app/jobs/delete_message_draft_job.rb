class DeleteMessageDraftJob < ApplicationJob
  def perform(message_draft)
    message_draft.destroy
  end
end
