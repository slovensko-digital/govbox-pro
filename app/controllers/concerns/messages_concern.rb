module MessagesConcern
  extend ActiveSupport::Concern

  included do
    helper_method :set_thread_tags_with_deletable_flag
  end

  def set_thread_tags_with_deletable_flag
    @thread_tags_with_deletable_flag =
      @message
        .thread
        .message_threads_tags
        .includes(:tag)
        .select("message_threads_tags.*, #{deletable_subquery('tags.id = message_threads_tags.tag_id').to_sql} as deletable")
        .order('tags.name')
  end

  def deletable_subquery(where_clause)
    Tag
      .joins(:groups, { groups: :group_memberships })
      .where('group_memberships.user_id = ?', Current.user.id)
      .where(where_clause)
      .arel
      .exists
  end
end
