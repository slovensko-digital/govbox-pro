# frozen_string_literal: true

class MessageThreadsTagPolicy < ApplicationPolicy
  attr_reader :user, :message_threads_tag

  def initialize(user, message_threads_tag)
    @user = user
    @message_threads_tag = message_threads_tag
  end

  class Scope < Scope
    def resolve
      scope_tags_to_accessible_by_user(scope)
    end

    def scope_tags_to_accessible_by_user(scope)
      # user can change tags on message_threads that he already has access to
      scope.where("EXISTS (
        SELECT 1 FROM message_threads_tags AS message_threads_tags_2
        INNER JOIN tag_groups ON tag_groups.tag_id = message_threads_tags_2.tag_id
        INNER JOIN group_memberships ON group_memberships.group_id = tag_groups.group_id
        WHERE group_memberships.user_id = ? AND message_threads_tags.message_thread_id = message_threads_tags_2.message_thread_id
      )", @user)
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
