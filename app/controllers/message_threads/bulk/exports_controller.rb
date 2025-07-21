# frozen_string_literal: true

module MessageThreads
  module Bulk
    class ExportsController < ApplicationController
      before_action :set_export, only: %i[show edit update start]

      def show
        authorize @export

        send_file @export.storage_path, type: 'application/x-zip-compressed', disposition: :download
      rescue
        redirect_back fallback_location: notifications_path, alert: "Export nie je možné stiahnuť."
      end

      def edit
        authorize @export

        @message_threads = message_thread_policy_scope.where(id: @export.message_thread_ids).includes(:messages)
        @message_forms = @message_threads.map do |thread|
          thread.metadata['fs_form_id']
        end.then do |ids|
          Fs::Form.where(id: ids).pluck(:slug)
        end
        @message_types = @message_threads.flat_map do |thread|
          thread.messages.map(&:message_type)
        end.uniq.compact
      end

      def create
        authorize ::Message
        ids = params[:message_thread_ids] || []
        filtered_ids = message_thread_policy_scope.where(id: ids).includes(:messages).pluck(:id)
        default_settings = Current.user.exports.last&.settings || { default: true } # get settings from previous export
        export = Current.user.exports.create!(message_thread_ids: filtered_ids, settings: default_settings)

        redirect_to edit_message_threads_bulk_export_path(export)
      end

      def update
        authorize @export

        if @export.update(export_params)
          redirect_to edit_message_threads_bulk_export_path(@export), notice: t("exports.flash.updated")
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def start
        authorize @export

        @export.start

        redirect_to root_path, notice: t("exports.flash.started")
      end

      private

      def message_thread_policy_scope
        policy_scope(MessageThread)
      end

      def set_export
        @export = policy_scope(Export).find(params[:id] || params[:export_id])
      end

      def export_params
        params.require(:export).permit(settings: {})
      end
    end
  end
end
