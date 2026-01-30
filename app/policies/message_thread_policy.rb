# frozen_string_literal: true

class MessageThreadPolicy < ApplicationPolicy
  attr_reader :user, :message_thread

  def initialize(user, message_thread)
    @user = user
    @message_thread = message_thread
  end

  class Scope < Scope
    def resolve
      scope.where(
        MessageThreadsTag
          .select(1)
          .joins(tag_groups: :group_memberships)
          .where("message_threads_tags.message_thread_id = message_threads.id")
          .where(group_memberships: { user_id: @user.id })
          .arel.exists
      )
    end
  end

  def show?
    true
  end

  def index?
    true
  end

  def scroll?
    true
  end

  def update?
    true
  end

  def bulk_merge?
    true
  end

  def bulk_actions?
    true
  end

  def rename?
    true
  end

  def history?
    true
  end

  def confirm_unarchive?
    true
  end

  def archive?
    true
  end

  def mark_read?
    true
  end
end
