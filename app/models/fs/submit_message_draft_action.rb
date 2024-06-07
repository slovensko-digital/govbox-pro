class Fs::SubmitMessageDraftAction
  def self.run(message, bulk: false)
    is_submittable = message.submittable?

    if is_submittable
      Fs::SubmitMessageDraftJob.perform_later(message, bulk: bulk)
      message.being_submitted!
    end

    is_submittable
  end
end
