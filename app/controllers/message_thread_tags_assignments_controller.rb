class MessageThreadTagsAssignmentsController < ApplicationController
  before_action :set_message_thread

  def edit
    authorize [MessageThreadsTag]

    set_tags_for_filter
    @init_tags_assignments = TagsAssignment.init(@all_tags, @message_thread.tag_ids)
    @new_tags_assignments = @init_tags_assignments

    @diff = TagsAssignment.make_diff(@init_tags_assignments, @new_tags_assignments, tag_scope)
  end

  def prepare
    authorize [MessageThreadsTag]

    @name_search = params[:name_search].strip
    set_tags_for_filter(@name_search)
    @init_tags_assignments = tags_assignments[:init].to_h
    @new_tags_assignments = tags_assignments[:new].to_h

    @diff = TagsAssignment.make_diff(@init_tags_assignments, @new_tags_assignments, tag_scope)
  end

  def update
    authorize [MessageThreadsTag]

    diff = TagsAssignment.make_diff(
      tags_assignments[:init].to_h,
      tags_assignments[:new].to_h,
      tag_scope
    )

    MessageThreadsTag.process_changes_for_message_thread(
      message_thread: @message_thread,
      tags_to_add: diff.to_add,
      tags_to_remove: diff.to_remove
    )

    # status: 303 is needed otherwise PATCH is kept in the following redirect https://apidock.com/rails/ActionController/Redirecting/redirect_to
    redirect_to message_thread_path(@message_thread), notice: "Priradenie štítkov bolo upravené", status: 303
  end

  private

  def set_message_thread
    @message_thread = message_thread_policy_scope.find(params[:id])
  end

  def set_tags_for_filter(name_search = "")
    @all_tags = tag_scope

    @filtered_tag_ids = @all_tags
    if name_search
      @filtered_tag_ids = @filtered_tag_ids.where('unaccent(name) ILIKE unaccent(?)', "%#{name_search}%")
    end
    @filtered_tag_ids = Set.new(@filtered_tag_ids.pluck(:id))
  end

  def tag_scope
    Current.tenant.tags.visible.order(:name)
  end

  def message_thread_policy_scope
    policy_scope(MessageThread)
  end

  def tags_assignments
    params.require(:tags_assignments).permit(:create_new_tag, init: {}, new: {})
  end
end
