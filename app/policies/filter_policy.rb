# frozen_string_literal: true

class FilterPolicy < ApplicationPolicy
  attr_reader :user, :filter

  def initialize(user, filter)
    @user = user
    @filter = filter
  end

  class ScopeEditable < Scope
    def resolve
      scoped = scope.where(tenant_id: @user.tenant_id)
      own = scoped.personal.where(author_id: @user.id)
      @user.admin? ? own.or(scoped.common) : own
    end
  end

  class ScopeShowable < Scope
    def resolve
      scope.available_to(@user)
    end
  end

  def index?
    true
  end

  def new?
    true
  end

  def create?
    true
  end

  def edit?
    same_tenant? && (@filter.common? ? @user.admin? : is_author_current_user?)
  end

  def update?
    edit?
  end

  def destroy?
    edit?
  end

  private

  def same_tenant?
    @filter.tenant_id == @user.tenant_id
  end

  def is_author_current_user?
    @filter.author == @user
  end
end
