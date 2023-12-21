module MessageThreads
  module Bulk
    class ArchivesController < ::ApplicationController
      def update
        authorize ::Message
        ids = params[:message_thread_ids] || []
        archived = params[:archived] == 'true'

        message_threads = message_thread_policy_scope.where(id: ids).includes(:messages)
        message_threads.transaction do
          message_threads.each { |message_thread| archive_message_thread(message_thread, archived) }

          notice = archived ?  "Vlákna boli zaradené na archiváciu" : "Vláknam bola zrušená archivácia"
          redirect_back fallback_location: message_threads_path, notice: notice, status: 303
        end
      end

      private

      def archive_message_thread(message_thread, archived)
        message_thread.archive(archived)
        message_thread.save
        Archivation::ArchiveMessageThreadJob.perform_later(message_thread) if archived
      end

      def message_thread_policy_scope
        policy_scope(MessageThread)
      end
    end
  end
end
