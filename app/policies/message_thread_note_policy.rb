# frozen_string_literal: true

class MessageThreadNotePolicy < ApplicationPolicy
  attr_reader :user, :message_thread_note

  def initialize(user, message_thread_note)
    @user = user
    @message_thread_note = message_thread_note
  end

  class Scope < Scope
    def resolve
      scope.joins(:message_thread).where(message_thread: Pundit.policy_scope(@user, MessageThread))
    end
  end

  def update?
    true
  end

  def create?
    true
  end
end
