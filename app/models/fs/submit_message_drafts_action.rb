class Fs::SubmitMessageDraftsAction
  def self.run(message_threads)

    messages = message_threads.map(&:message_drafts).where(type: 'Fs::MessageDraft').flatten

    results = messages.map { |message| ::Fs::SubmitMessageDraftAction.run(message,) }
    results.select { |value| value }.present?
  end
end
