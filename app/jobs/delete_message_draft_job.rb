class DeleteMessageDraftJob < ApplicationJob
  def perform
    batch.properties[:message_draft].destroy
  end
end