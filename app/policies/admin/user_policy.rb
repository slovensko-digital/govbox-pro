# frozen_string_literal: true

class Admin::UserPolicy < ApplicationPolicy
  def initialize(actor, user_to_authorize)
    @actor = actor
    @user_to_authorize = user_to_authorize
  end

  def user
    @actor
  end

  class Scope < Scope
    def initialize(actor, scope)
      @actor = actor
      @scope = scope
    end

    def user
      @actor
    end

    def resolve
      scope.where(tenant: @actor.tenant)
    end
  end

  def index?
    @actor.admin?
  end

  def show?
    @actor.admin?
  end

  def create?
    @actor.admin?
  end

  def new?
    create?
  end

  def update?
    @actor.admin?
  end

  def edit?
    update?
  end

  def destroy?
    return false unless @actor.admin?
    return false if @user_to_authorize == @actor

    true
  end
end
