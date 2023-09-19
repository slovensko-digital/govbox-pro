# frozen_string_literal: true

class Admin::TagPolicy < ApplicationPolicy
  attr_reader :user, :tag

  def initialize(user, tag)
    @user = user
    @tag = tag
  end

  class Scope < Scope
    def resolve
      @user.site_admin? ? scope.all : scope.where(tenant: @user.tenant)
    end
  end

  def index?
    @user.site_admin? || @user.admin?
  end

  def show?
    @user.site_admin? || @user.admin?
  end

  def create?
    @user.site_admin? || @user.admin?
  end

  def new?
    create?
  end

  def update?
    @user.site_admin? || @user.admin?
  end

  def edit?
    update?
  end

  def visibility_toggle?
    update?
  end

  def destroy?
    @user.site_admin? || @user.admin?
  end
end
