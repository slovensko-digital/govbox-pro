module MessageThreads
  module Bulk
    class MessageDraftsController < ::ApplicationController
      def submit
        authorize ::MessageDraft, :submit?

        ids = params[:message_thread_ids] || []

        message_threads = message_thread_policy_scope.where(id: ids).includes(:messages)
        message_threads.transaction do
          submission_results = [Govbox::SubmitMessageDraftsAction.run(message_threads), Fs::SubmitMessageDraftsAction.run(message_threads)].flatten
          if submission_results
            redirect_back fallback_location: message_threads_path, notice: "Správy vo vláknach boli zaradené na odoslanie", status: 303
          else
            redirect_back fallback_location: message_threads_path, alert: "Vo vláknach sa nenašli žiadne správy na odoslanie", status: 303
          end
        end
      end

      private

      def message_thread_policy_scope
        policy_scope(MessageThread)
      end
    end
  end
end
