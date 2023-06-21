# frozen_string_literal: true

class Admin::GroupMembershipPolicy < ApplicationPolicy
  attr_reader :user, :group_membership

  def initialize(user, group_membership)
    @user = user
    @group_membership = group_membership
  end

  class Scope < Scope
    def resolve
      if @user.site_admin?
        scope.all
      else
        scope.includes(:user, :group).where(user: {tenant_id: Current.tenant.id}, group: {tenant_id: Current.tenant.id})
      end
    end
  end

  def index
    @user.site_admin? || @user.admin?
  end

  def show?
    @user.site_admin? || @user.admin?
  end

  def create?
    return false if !@user.site_admin? && !@user.admin?
    return false unless @group_membership.group.tenant == Current.tenant
    return false unless @group_membership.user.tenant == Current.tenant

    true
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

  def destroy?
    @user.site_admin? || @user.admin?
  end
end

