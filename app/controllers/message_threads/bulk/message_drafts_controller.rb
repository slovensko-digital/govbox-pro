module MessageThreads
  module Bulk
    class MessageDraftsController < ::ApplicationController
      def submit
        authorize ::MessageDraft, :submit?

        ids = params[:message_thread_ids] || []

        message_threads = message_thread_policy_scope.where(id: ids).includes(:messages)
        message_threads.transaction do
          submission_results = SubmitMessageDraftsAction.run(message_threads)
          if submission_results.none?(true)
            redirect_back fallback_location: message_threads_path, alert: "Vo vláknach sa našli správy, ktoré neboli podpísané všetkými podpismi", status: 303 and return if any_missing_signature?(message_threads)
            redirect_back fallback_location: message_threads_path, alert: "Vo vláknach sa nenašli žiadne správy na odoslanie", status: 303
          else
            redirect_back fallback_location: message_threads_path, alert: "Správy, ktoré neboli podpísané všetkými podpismi neboli zaradené na odoslanie", status: 303 and return if any_missing_signature?(message_threads)
            redirect_back fallback_location: message_threads_path, notice: "Správy vo vláknach boli zaradené na odoslanie", status: 303
          end
        end
      end

      def destroy
        authorize ::MessageDraft, :destroy?

        ids = params[:message_thread_ids] || []

        message_threads = message_thread_policy_scope.where(id: ids).includes(:messages)
        message_drafts_to_destroy_ids = message_threads.map(&:message_drafts).flatten.map(&:id)

        message_threads.transaction do
          MessageDraft.where(id: message_drafts_to_destroy_ids).destroy_all
        end

        if message_drafts_to_destroy_ids.present?
          redirect_back fallback_location: message_threads_path, notice: "Rozpracované správy vo vláknach boli zahodené", status: 303
        else
          redirect_back fallback_location: message_threads_path, alert: "Vo vláknach sa nenašli žiadne rozpracované správy na zahodenie", status: 303
        end
      end

      private

      def message_thread_policy_scope
        policy_scope(MessageThread)
      end

      def any_missing_signature?(message_threads)
        message_threads.any? { |thread| thread.any_objects_with_requested_signature? }
      end
    end
  end
end
