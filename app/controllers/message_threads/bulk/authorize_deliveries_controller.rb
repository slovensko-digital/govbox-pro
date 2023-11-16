module MessageThreads
  module Bulk
    class AuthorizeDeliveriesController < ::ApplicationController
      def update
        authorize ::Message, :authorize_delivery_notification?

        ids = params[:message_thread_ids] || []

        message_threads = message_thread_policy_scope.where(id: ids).includes(:messages)
        if Govbox::AuthorizeDeliveryNotificationsAction.run(message_threads)
          redirect_back fallback_location: message_threads_path, notice: "Správy vo vláknach boli zaradené na prevzatie", status: 303
        else
          redirect_back fallback_location: message_threads_path, alert: "Vo vláknach sa nenašli žiadne správy na prevzatie", status: 303
        end
      end

      private

      def message_thread_policy_scope
        policy_scope(MessageThread)
      end
    end
  end
end
