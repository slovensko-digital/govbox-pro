class Fs::SubmitMessageDraftsAction
  def self.run(message_threads)

    messages = []
    message_threads.each { |thread| messages << thread.messages.where(type: 'Fs::MessageDraft') }

    results = messages.flatten.map { |message| ::Fs::SubmitMessageDraftAction.run(message, bulk: true) }
    results.select { |value| value }.present?
  end
end
