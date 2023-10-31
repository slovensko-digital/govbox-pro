# frozen_string_literal: true

class MessageThreadsTagPolicy < ApplicationPolicy
  attr_reader :user, :message_threads_tag

  def initialize(user, message_threads_tag)
    @user = user
    @message_threads_tag = message_threads_tag
  end

  class Scope < Scope
    def resolve
      return scope.all if @user.site_admin?

      # user can change tags on message_threads that he already has access to
      scope.where(threads_accessed_by_user(@user.id))
    end

    def threads_accessed_by_user(user_id)
      message_thread_tag_table = MessageThreadsTag.arel_table.alias('message_threads_tags_2')
      tag_group_table = TagGroup.arel_table
      group_membership_table = GroupMembership.arel_table

      query = Arel::SelectManager.new(message_thread_tag_table)
      query.project(1) # select 1
      query.join(tag_group_table).on(tag_group_table[:tag_id].eq(message_thread_tag_table[:tag_id]))
      query.join(group_membership_table).on(group_membership_table[:group_id].eq(tag_group_table[:group_id]))
      query.where(group_membership_table[:user_id].eq(user_id))
      query.where(Arel::Nodes::SqlLiteral.new("message_threads_tags.message_thread_id = message_threads_tags_2.message_thread_id"))

      query.exists
    end
  end

  def index
    true
  end

  def show?
    true
  end

  def create?
    true
  end

  def new?
    create?
  end

  def update?
    true
  end

  def edit?
    update?
  end

  def destroy?
    true
  end

  def prepare?
    true
  end
end

