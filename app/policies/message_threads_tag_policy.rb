# frozen_string_literal: true

class MessageThreadsTagPolicy < ApplicationPolicy
  attr_reader :user, :message_threads_tag

  def initialize(user, message_threads_tag)
    @user = user
    @message_threads_tag = message_threads_tag
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

  def prepare?
    true
  end
end
