# frozen_string_literal: true

class Admin::GroupMembershipPolicy < ApplicationPolicy
  attr_reader :user, :group_membership

  def initialize(user, group_membership)
    @user = user
    @group_membership = group_membership
  end

  class Scope < Scope
    def resolve
      scope.includes(:user, :group).where(user: { tenant: Current.tenant }, group: { tenant: Current.tenant })
    end
  end

  def index
    @user.admin?
  end

  def show?
    @user.admin?
  end

  def create?
    return false unless @user.admin?
    return false unless @group_membership.group.tenant == Current.tenant
    return false unless @group_membership.user.tenant == Current.tenant

    true
  end

  def new?
    create?
  end

  def update?
    @user.admin?
  end

  def edit?
    update?
  end

  def destroy?
    @user.admin?
  end
end
