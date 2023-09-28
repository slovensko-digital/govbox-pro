# frozen_string_literal: true

class FilterPolicy < ApplicationPolicy
  attr_reader :user, :filter

  def initialize(user, filter)
    @user = user
    @filter = filter
  end

  class Scope < Scope
    def resolve
      scoped = scope.where(tenant_id: Current.tenant)

      return scoped if @user.admin? || @user.site_admin?

      scoped.where(author_id: @user.id)
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
    true if @user.admin? || @user.site_admin?

    @filter.author_id == @user.id
  end

  def update?
    true if @user.admin? || @user.site_admin?

    @filter.author_id == @user.id
  end

  def destroy?
    true if @user.admin? || @user.site_admin?

    @filter.author_id == @user.id
  end
end
