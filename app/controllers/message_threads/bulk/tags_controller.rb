module MessageThreads
  module Bulk
    class TagsController < ::ApplicationController
      before_action :set_message_threads

      include TagCreation

      def edit
        authorize MessageThreadsTag

        @tags_changes = TagsChanges.new(
          tag_scope: tag_scope,
          tags_assignments: TagsChanges::Helpers.build_bulk_assignments(message_threads: @message_threads, tag_scope: tag_scope)
        )
        @tags_filter = TagsFilter.new(tag_scope: tag_scope)
      end

      def prepare
        authorize MessageThreadsTag

        @tags_changes = TagsChanges.new(
          tag_scope: tag_scope,
          tags_assignments: tags_assignments,
          )
        @tags_filter = TagsFilter.new(tag_scope: tag_scope, filter_query: params[:name_search_query].strip)
        @rerender_list = params[:assignments_update].blank?
      end

      def create_tag
        new_tag = SimpleTag.new(simple_tag_creation_params.merge(name: params[:new_tag].strip))
        authorize(new_tag, "create?", policy_class: TagPolicy)

        @tags_changes = TagsChanges.new(
          tag_scope: tag_scope,
          tags_assignments: tags_assignments,
          )

        @tags_changes.add_new_tag(new_tag) if new_tag.save

        @tags_filter = TagsFilter.new(tag_scope: tag_scope, filter_query: "")
        @rerender_list = true
        @reset_search = true

        render :prepare
      end

      def update
        authorize MessageThreadsTag

        tag_changes = TagsChanges.new(
          tag_scope: tag_scope.includes(:tenant),
          tags_assignments: tags_assignments
        )

        tag_changes.bulk_save(@message_threads.includes(box: :tenant))

        # status: 303 is needed otherwise PATCH is kept in the following redirect https://apidock.com/rails/ActionController/Redirecting/redirect_to
        redirect_back fallback_location: message_threads_path, notice: "Priradenie štítkov bolo upravené", status: 303
      end

      private

      def tag_scope
        SimpleTag.where(tenant: Current.tenant).visible.order(:name)
      end

      def message_thread_policy_scope
        policy_scope(MessageThread)
      end

      def set_message_threads
        ids = params[:message_thread_ids] || []

        @message_threads = message_thread_policy_scope.where(id: ids)
      end

      def tags_assignments
        params.require(:tags_assignments).permit(init: {}, new: {})
      end
    end

  end
end
