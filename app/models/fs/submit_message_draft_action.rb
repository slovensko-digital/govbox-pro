class Fs::SubmitMessageDraftAction
  def self.run(message, bulk: false, priority_level: :medium_priority)
    is_submittable = message.submittable?

    if is_submittable
      Fs::SubmitMessageDraftJob.set(queue: priority_level).perform_later(message, bulk_submit: bulk)
      message.being_submitted!
    end

    is_submittable
  end
end
