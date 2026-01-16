# frozen_string_literal: true

class Admin::GroupPolicy < ApplicationPolicy
  attr_reader :user, :group

  def initialize(user, group)
    @user = user
    @group = group
  end

  class Scope < Scope
    def resolve
      scope.where(tenant: @user.tenant)
    end
  end

  def index?
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
    return false unless @group.editable?

    @user.admin?
  end

  def edit?
    update?
  end

  def edit_members?
    update?
  end

  def show_members?
    @user.admin?
  end

  def edit_permissions?
    @user.admin?
  end

  def destroy?
    return false if @group.system?

    @user.admin?
  end

  def search_non_members?
    @user.admin?
  end

  def search_non_tags?
    @user.admin?
  end

  def search_non_boxes?
    @user.admin?
  end
end
