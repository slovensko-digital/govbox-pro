# frozen_string_literal: true

class MessageObjectPolicy < ApplicationPolicy
  attr_reader :user, :message_object

  def initialize(user, message_object)
    @user = user
    @message_object = message_object
  end

  class Scope < Scope
    def resolve
      if @user.site_admin?
        scope.all
      else
        scope.where(
          'message_id in (
        select m.id
        from messages m
        join message_threads mt on mt.id = m.message_thread_id
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

  def download?
    true
  end
end
