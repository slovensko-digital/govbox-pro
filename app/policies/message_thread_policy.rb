# frozen_string_literal: true

class MessageThreadPolicy < ApplicationPolicy
  attr_reader :user, :message_thread

  def initialize(user, message_thread)
    @user = user
    @message_thread = message_thread
  end

  class Scope < Scope
    def resolve
      if @user.site_admin?
        scope.all
      else
        scope.where(
          'id in (
        select mt.id
        from message_threads mt
        join message_threads_tags mt_tags on mt.id = mt_tags.message_thread_id
        join tag_users tu on mt_tags.tag_id = tu.tag_id
        where user_id = ?)',
          @user.id
        )
      end
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
