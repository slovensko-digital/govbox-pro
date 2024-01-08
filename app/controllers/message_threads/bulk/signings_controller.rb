module MessageThreads
  module Bulk
    class SigningsController < ::ApplicationController
      before_action :set_message_ids
      before_action :set_message_objects
      before_action :nothing_to_sign_redirect, only: %i[new start]

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
        @message_thread_ids = params[:message_thread_ids] || []
      end

      def set_message_objects
        @message_objects = MessageObject.joins(:tags, message: :thread).
          where(message_threads: { id: @message_thread_ids }).
          where(tags: { id: Current.user.signature_requested_from_tag })
      end

      def nothing_to_sign_redirect
        if @message_objects.blank?
          request_turbo_reload
          redirect_back fallback_location: message_threads_path, alert: t("bulk.signing.nothing_to_sign"), status: 303
        end
      end
    end
  end
end
