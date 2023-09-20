class Govbox::SubmitMultipleMessageDraftsJob < ApplicationJob
  def perform(message_drafts, jobs_batch: GoodJob::Batch.new)
    message_drafts.each { |message_draft| message_draft.submit(jobs_batch: jobs_batch) }

    jobs_batch.enqueue(on_finish: Govbox::FinishMessageDraftsSubmitJob, box: message_drafts.first.thread.folder.box)
  end
end
