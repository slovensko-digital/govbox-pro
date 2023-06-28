# frozen_string_literal: true

class MessagesTagPolicy < ApplicationPolicy
  attr_reader :user, :messages_tag

  def initialize(user, messages_tag)
    @user = user
    @messages_tag = messages_tag
  end

  class Scope < Scope
    def resolve
      if @user.site_admin?
        scope.all
      else
        # TODO: toto zrejme nestaci, potrebujeme obmedzit aj na konkretneho usera a jeho boxy
        scope.includes(:message, :tag).where(message: {tenant_id: Current.tenant.id}, tag: {tenant_id: Current.tenant.id})
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

