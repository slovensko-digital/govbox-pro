# frozen_string_literal: true

class MessageDraftPolicy < ApplicationPolicy
  attr_reader :user, :message

  def initialize(user, message)
    @user = user
    @message = message
  end

  class Scope < Scope
    def resolve
      return scope.all if @user.site_admin?

      scope.where(
        MessageThreadsTag
          .select(1)
          .joins(tag_groups: :group_memberships)
          .where("message_threads_tags.message_thread_id = messages.message_thread_id")
          .where(group_memberships: { user_id: @user.id })
          .arel.exists
      )
    end
  end

  def create?
    true # TODO can everyone create new messages?
  end

  def show?
    true
  end

  def update?
    create?
  end

  def submit?
    create?
  end

  def destroy?
    create?
  end
end
