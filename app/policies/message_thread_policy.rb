# frozen_string_literal: true

class MessageThreadPolicy < ApplicationPolicy
  attr_reader :user, :message_thread

  def initialize(user, message_thread)
    @user = user
    @message_thread = message_thread
  end

  class Scope < Scope
    def resolve
      return scope.all if @user.site_admin?

      scope.where(
        'id IN (
      SELECT message_thread_id FROM message_threads_tags mt_tags
      JOIN tag_groups tg on mt_tags.tag_id = tg.tag_id
      JOIN group_memberships gm on tg.group_id = gm.group_id
      WHERE gm.user_id = ?)',
        @user.id
      )
    end
  end

  def show?
    true
  end

  def index?
    true
  end

  def update?
    true
  end

  def merge?
    true
  end
end
