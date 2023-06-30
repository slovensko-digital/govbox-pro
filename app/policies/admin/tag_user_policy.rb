# frozen_string_literal: true

class Admin::TagUserPolicy < ApplicationPolicy
  attr_reader :user, :tag_user

  def initialize(user, tag_user)
    @user = user
    @tag_user = tag_user
  end

  class Scope < Scope
    def resolve
      if @user.site_admin?
        scope.all
      else
        scope.includes(:user, :tag).where(user: { tenant_id: Current.tenant.id }, tag: { tenant_id: Current.tenant.id })
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
    return false unless @tag_user.tag.tenant == Current.tenant
    return false unless @tag_user.user.tenant == Current.tenant

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
