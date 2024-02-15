class Govbox::SubmitMessageDraftsAction
  def self.run(message_threads)
    messages = message_threads.map(&:messages).flatten

    results = messages.map { |message| ::Govbox::SubmitMessageDraftAction.run(message) }

    results.select { |value| value }.present?
  end
end
