# frozen_string_literal: true

class Admin::TenantPolicy < ApplicationPolicy
  attr_reader :user, :tenant

  def initialize(user, tenant)
    @user = user
    @tenant = tenant
  end

  class Scope < Scope
    def resolve
      if @user.site_admin?
        scope.all
      else
        scope.where(id: @user.tenant_id)
      end
    end
  end

  def index?
    @user.site_admin? || @user.admin?
  end

  def show?
    @user.site_admin? || @user.admin?
  end

  def create?
    @user.site_admin?
  end

  def new?
    create?
  end

  def update?
    @user.site_admin?
  end

  def edit?
    update?
  end

  def destroy?
    @user.site_admin?
  end
end
