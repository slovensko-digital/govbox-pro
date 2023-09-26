# frozen_string_literal: true

class Admin::TagGroupPolicy < ApplicationPolicy
  attr_reader :user, :tag_group

  def initialize(user, tag_group)
    @user = user
    @tag_group = tag_group
  end

  class Scope < Scope
    def resolve
      if @user.site_admin?
        scope.all
      else
        scope.includes(:group, :tag).where(group: { tenant_id: Current.tenant.id }, tag: { tenant_id: Current.tenant.id })
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
    return false if !@user.site_admin? && !@user.admin?
    return false unless @tag_group.tag.tenant == Current.tenant
    return false unless @tag_group.group.tenant == Current.tenant

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
