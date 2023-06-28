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
        # TODO: toto zrejme nestaci, potrebujeme obmedzit aj na konkretneho usera a jeho boxy
        scope.includes(:message_thread, :tag).where(message_thread: {tenant_id: Current.tenant.id}, tag: {tenant_id: Current.tenant.id})
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

