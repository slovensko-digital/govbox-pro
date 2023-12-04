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
      if @actor.site_admin?
        scope.all
      else
        scope.where(tenant_id: @actor.tenant_id)
      end
    end
  end

  def index?
    @actor.site_admin? || @actor.admin?
  end

  def show?
    @actor.site_admin? || @actor.admin?
  end

  def create?
    @actor.site_admin? || @actor.admin?
  end

  def new?
    create?
  end

  def update?
    @actor.site_admin? || @actor.admin?
  end

  def edit?
    update?
  end

  def destroy?
    return false unless @actor.site_admin? || @actor.admin?
    return false if @user_to_authorize == @actor

    true
  end
end
