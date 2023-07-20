# frozen_string_literal: true

class MessagePolicy < ApplicationPolicy
  attr_reader :user, :message

  def initialize(user, message)
    @user = user
    @message = message
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
        join tag_users tu on mt_tags.tag_id = tu.tag_id
        where user_id = ?)',
          @user.id
        )
      end
    end
  end

  def create?
    true
  end

  def show?
    true
  end

  def reply?
    true # TODO can everyone reply?
  end

  def submit_reply?
    reply?
  end
end
