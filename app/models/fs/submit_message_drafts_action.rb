class Fs::SubmitMessageDraftsAction
  def self.run(message_threads, priority: :default)

    messages = []
    message_threads.each { |thread| messages << thread.messages.where(type: 'Fs::MessageDraft') }

    results = messages.flatten.map { |message| ::Fs::SubmitMessageDraftAction.run(message, bulk: true, priority: priority) }
    results.select { |value| value }.present?
  end
end
