# frozen_string_literal: true

class MessageThreadsTagPolicy < ApplicationPolicy
  attr_reader :user, :message_threads_tag

  def initialize(user, message_threads_tag)
    @user = user
    @message_threads_tag = message_threads_tag
  end

  class Scope < Scope
    def resolve
      if @user.site_admin?
        scope.all
      else
        scope.where(
          'message_thread_id in (
        select mt.id
        from message_threads mt
        join message_threads_tags mt_tags on mt.id = mt_tags.message_thread_id
        join tag_groups tg on mt_tags.tag_id = tg.tag_id
        join group_memberships gm on tg.group_id = gm.group_id
        where user_id = ?)',
          @user.id
        ).where(
          "tag_id in (
        select tag_id
        from tag_groups tg
        join group_memberships gm on tg.group_id = gm.group_id
        where user_id = ?)",
          @user.id
        )
      end
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
end

