class Govbox::SubmitMessageDraftAction
  def self.run(message, jobs_batch: nil, priority_level: :medium_priority)
    is_submittable = message.submittable?

    if is_submittable
      if jobs_batch
        jobs_batch.add { Govbox::SubmitMessageDraftJob.perform_later(message, bulk_submit: true) }
      else
        Govbox::SubmitMessageDraftJob.set(queue: priority_level).perform_later(message)
      end

      message.being_submitted!
    end

    is_submittable
  end
end
