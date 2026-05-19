class Fs::SubmitMessageDraftAction
  def self.run(message, bulk: false)
    is_submittable = message.submittable?

    if is_submittable
      if bulk
        Fs::SubmitMessageDraftJob.set(job_context: :asap_bulk).perform_later(message, bulk_submit: bulk)
      else
        Fs::SubmitMessageDraftJob.set(job_context: :asap).perform_later(message)
      end
      message.being_submitted!
    end

    is_submittable
  end
end
