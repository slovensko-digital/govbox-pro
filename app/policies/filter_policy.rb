# frozen_string_literal: true

class FilterPolicy < ApplicationPolicy
  attr_reader :user, :filter

  def initialize(user, filter)
    @user = user
    @filter = filter
  end

  class ScopeEditable < Scope
    def resolve
      scoped = scope.where(tenant_id: Current.tenant)

      return scoped if @user.admin?

      scoped.where(author_id: @user.id)
    end
  end

  class ScopeShowable < Scope
    def resolve
      scope.where(tenant_id: Current.tenant)
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
    true if @user.admin?

    is_author_current_user?
  end

  def update?
    true if @user.admin?

    is_author_current_user?
  end

  def destroy?
    true if @user.admin?

    is_author_current_user?
  end

  private

  def is_author_current_user?
    @filter.author == @user
  end
end
