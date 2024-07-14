class SubmitMessageDraftsAction
  def self.run(message_threads)
    [
      Govbox::SubmitMessageDraftsAction.run(message_threads),
      Fs::SubmitMessageDraftsAction.run(message_threads)
    ].flatten
  end
end
