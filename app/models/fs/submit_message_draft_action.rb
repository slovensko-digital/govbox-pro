class Fs::SubmitMessageDraftAction
  def self.run(message)
    is_submittable = message.submittable?

    if is_submittable
      Fs::SubmitMessageDraftJob.perform_later(message)
      message.being_submitted!
    end

    is_submittable
  end
end