module MessageThreads
  module Bulk
    class SigningsController < ::ApplicationController
      before_action :set_message_ids
      before_action :set_message_objects
      before_action :redirect_on_no_signable_objects, only: %i[new start]

      include TurboReload

      def new
        authorize MessageObjectsTag
      end

      def start
        authorize MessageObjectsTag
      end

      def update
        authorize MessageObjectsTag

        if params[:result] == "ok"
          redirect_back fallback_location: message_threads_path, notice: t("signing.processed"), status: 303
        else
          redirect_back fallback_location: message_threads_path, alert: t("signing.failed"), status: 303
        end
      end

      private

      def set_message_ids
        @message_thread_ids = message_thread_policy_scope.where(id: params[:message_thread_ids] || []).pluck(:id)
      end

      def set_message_objects
        @message_objects = message_object_policy_scope.joins(:tags, message: :thread).
          where(message_threads: { id: @message_thread_ids }).
          where(tags: { id: Current.user.signature_requested_from_tag })
      end

      def message_thread_policy_scope
        policy_scope(MessageThread)
      end

      def message_object_policy_scope
        policy_scope(MessageObject)
      end

      def redirect_on_no_signable_objects
        if @message_objects.blank?
          request_turbo_reload
          redirect_back fallback_location: message_threads_path, alert: t("bulk.signing.nothing_to_sign"), status: 303
        end
      end
    end
  end
end
