# frozen_string_literal: true

class GroupPolicy < ApplicationPolicy
  attr_reader :user, :group

  def initialize(user, group)
    @user = user
    @group = group
  end

  class Scope < Scope
    def resolve
      if @user.site_admin?
        scope.all
      else
        scope.where(tenant_id: @user.tenant_id)
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

  def destroy?
    @user.site_admin? || @user.admin?
  end

end
