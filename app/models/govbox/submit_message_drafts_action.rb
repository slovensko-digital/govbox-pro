class Govbox::SubmitMessageDraftsAction
  def self.run(message_threads)
    jobs_batch = GoodJob::Batch.new

    messages = []
    message_threads.each { |thread| messages << thread.messages.where(type: 'Upvs::MessageDraft') }

    results = messages.flatten.map { |message| ::Govbox::SubmitMessageDraftAction.run(message, jobs_batch: jobs_batch) }
    submittable_messages = results.select { |value| value }.present?

    if submittable_messages
      boxes_to_sync = Current.tenant.boxes.joins(message_threads: :messages).where(messages: { id: messages.map(&:id) }).uniq
      jobs_batch.enqueue(on_finish: Govbox::ScheduleDelayedSyncBoxJob, boxes: boxes_to_sync)
    end

    submittable_messages
  end
end
