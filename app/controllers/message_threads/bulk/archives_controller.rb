module MessageThreads
  module Bulk
    class ArchivesController < ::ApplicationController
      def update
        authorize ::Message
        ids = params[:message_thread_ids] || []

        message_threads = message_thread_policy_scope.where(id: ids).includes(:messages)
        message_threads.transaction do
          message_threads.each do |message_thread|
            message_thread.archived(true)
            message_thread.save
            Archivation::ArchiveMessageThreadJob.perform_later(message_thread)
          end

          redirect_back fallback_location: message_threads_path, notice: "Vlákna boli zaradené na archiváciu", status: 303
        end
      end

      private

      def message_thread_policy_scope
        policy_scope(MessageThread)
      end
    end
  end
end
