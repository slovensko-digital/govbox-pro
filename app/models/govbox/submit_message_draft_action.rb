class Govbox::SubmitMessageDraftAction
  def self.run(message)
    is_submittable = message.submittable?

    if is_submittable
      Govbox::SubmitMessageDraftJob.perform_later(message)
      message.being_submitted!
    end

    is_submittable
  end
end
