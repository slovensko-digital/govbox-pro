class MessageThreads::TagsController < ApplicationController
  before_action :set_message_thread

  include TagCreation

  def edit
    authorize MessageThreadsTag

    @tags_changes = RelationChanges::Tags.new(
      tag_scope: tag_scope,
      tags_assignments: RelationChanges::Tags.build_assignment(message_thread: @message_thread, tag_scope: tag_scope)
    )

    @tags_filter = TagsFilter.new(tag_scope: tag_scope)
  end

  def prepare
    authorize MessageThreadsTag

    @tags_changes = RelationChanges::Tags.new(
      tag_scope: tag_scope,
      tags_assignments: tags_assignments
    )

    @tags_filter = TagsFilter.new(tag_scope: tag_scope, filter_query: params[:name_search_query].strip)
    @rerender_list = params[:assignments_update].blank?
  end

  def create_tag
    new_tag = SimpleTag.new(simple_tag_creation_params.merge(name: params[:new_tag].strip))
    authorize(new_tag, "create?", policy_class: TagPolicy)

    @tags_changes = RelationChanges::Tags.new(
      tag_scope: tag_scope,
      tags_assignments: tags_assignments
    )
    @tags_changes.add_new_tag(new_tag) if new_tag.save

    @tags_filter = TagsFilter.new(tag_scope: tag_scope, filter_query: "")
    @rerender_list = true
    @reset_search = true

    render :prepare
  end

  def update
    authorize MessageThreadsTag

    tag_changes = RelationChanges::Tags.new(
      tag_scope: tag_scope,
      tags_assignments: tags_assignments
    )

    tag_changes.save(@message_thread)

    # status: 303 is needed otherwise PATCH is kept in the following redirect https://apidock.com/rails/ActionController/Redirecting/redirect_to
    redirect_to message_thread_path(@message_thread), notice: "Priradenie štítkov bolo upravené", status: 303
  end

  private

  def set_message_thread
    @message_thread = message_thread_policy_scope.find(params[:message_thread_id])
  end

  def tag_scope
    Current.tenant.simple_tags.visible.order(:name)
  end

  def message_thread_policy_scope
    policy_scope(MessageThread)
  end

  def tags_assignments
    params.require(:tags_assignments).permit(init: {}, new: {}) || params.require(:quick_tags_assignments).permit(init: {}, new: {})
  end
end
