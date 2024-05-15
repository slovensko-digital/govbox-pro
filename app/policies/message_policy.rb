# frozen_string_literal: true

class MessagePolicy < ApplicationPolicy
  attr_reader :user, :message

  def initialize(user, message)
    @user = user
    @message = message
  end

  class Scope < Scope
    def resolve
      scope.where(
        MessageThreadsTag
          .select(1)
          .joins(tag_groups: :group_memberships)
          .where('message_threads_tags.message_thread_id = messages.message_thread_id')
          .where(group_memberships: { user_id: @user.id })
          .arel.exists
      )
    end
  end

  def new?
    true
  end

  def create?
    true
  end

  def show?
    true
  end

  def export?
    show?
  end

  def authorize_delivery_notification?
    show?
  end

  def reply?
    true # TODO: can everyone reply?
  end

  def submit_reply?
    reply?
  end

  def update?
    true
  end
end
