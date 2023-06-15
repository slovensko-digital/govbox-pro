# frozen_string_literal: true

class Admin::BoxPolicy < ApplicationPolicy
  attr_reader :user, :box

  def initialize(user, box)
    @user = user
    @box = box
  end

  class Scope < Scope
    def resolve
      @user.site_admin? ? scope.all : scope.where(tenant_id: @user.tenant_id)
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
