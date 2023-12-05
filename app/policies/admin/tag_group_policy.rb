# frozen_string_literal: true

class Admin::TagGroupPolicy < ApplicationPolicy
  attr_reader :user, :tag_group

  def initialize(user, tag_group)
    @user = user
    @tag_group = tag_group
  end

  class Scope < Scope
    def resolve
      scope.includes(:group, :tag).where(group: { tenant: Current.tenant }, tag: { tenant: Current.tenant })
    end
  end

  def index?
    @user.admin?
  end

  def show?
    @user.admin?
  end

  def create?
    return false unless @user.admin?
    return false unless @tag_group.tag.tenant == Current.tenant
    return false unless @tag_group.group.tenant == Current.tenant

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
