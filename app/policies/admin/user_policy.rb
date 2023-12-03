# frozen_string_literal: true

class Admin::UserPolicy < ApplicationPolicy
  attr_reader :user

  def initialize(user_logged_in, user_to_authorize)
    @user = user_logged_in
    @user_to_authorize = user_to_authorize
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

  def destroy?
    (@user.site_admin? || @user.admin?) && @user_to_authorize != @user
  end
end
