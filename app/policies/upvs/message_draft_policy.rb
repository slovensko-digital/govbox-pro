# frozen_string_literal: true

class ::Upvs::MessageDraftPolicy < ApplicationPolicy
  attr_reader :user, :message

  def initialize(user, message)
    @user = user
    @message = message
  end

  class Scope < Scope
    def resolve
      # TODO: this does not work for imported drafts (no tags present)
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

  def new?
    true
  end

  def index?
    true
  end

  def create?
    true # TODO: can everyone create new messages?
  end

  def reply?
    true
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

  def confirm_unlock?
    unlock?
  end

  def unlock?
    create?
  end
end
