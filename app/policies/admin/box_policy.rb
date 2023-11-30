# frozen_string_literal: true

class Admin::BoxPolicy < ApplicationPolicy
  attr_reader :user, :box

  def initialize(user, box)
    @user = user
    @box = box
  end

  class Scope < Scope
    def resolve
      scope.where(tenant: @user.tenant)
    end
  end

  def index
    @user.admin?
  end

  def show?
    @user.admin?
  end

  def create?
    @user.admin?
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
