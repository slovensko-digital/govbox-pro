class MessageThreadTagsAssignmentsController < ApplicationController
  before_action :set_message_thread

  def edit
    authorize MessageThreadsTag

    @tags_changes = TagsChanges.init(
      message_thread: @message_thread,
      tag_scope: tag_scope,
    )

    set_tags_for_filter
  end

  def prepare
    authorize MessageThreadsTag

    @tags_changes = TagsChanges.prepare(
      message_thread: @message_thread,
      tag_scope: tag_scope,
      tags_assignments: tags_assignments.to_h
    )

    @name_search_query = params[:name_search_query].strip

    set_tags_for_filter(@name_search_query)
  end

  def create_tag
    new_tag = Tag.new(tag_creation_params.merge(name: params[:new_tag].strip))
    authorize(new_tag, "create?")

    @tags_changes = TagsChanges.new(
      message_thread: @message_thread,
      tag_scope: tag_scope,
      tags_assignments: tags_assignments.to_h
    )

    @tags_changes.add_new_tag(new_tag) if new_tag.save
    @tags_changes.build_diff

    @reset_search_filter = true
    @name_search_query = ""

    set_tags_for_filter(@name_search_query)

    render :prepare
  end

  def update
    authorize MessageThreadsTag

    tag_changes = TagsChanges.new(
      message_thread: @message_thread,
      tag_scope: tag_scope,
      tags_assignments: tags_assignments.to_h
    )

    tag_changes.save

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
    params.require(:tags_assignments).permit(init: {}, new: {})
  end

  def tag_creation_params
    {
      owner: Current.user,
      tenant: Current.tenant,
      groups: [Current.user.user_group]
    }
  end
end
