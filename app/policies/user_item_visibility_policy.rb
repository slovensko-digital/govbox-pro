# frozen_string_literal: true

class UserItemVisibilityPolicy < ApplicationPolicy
  attr_reader :user, :user_item_visible

  def initialize(user, user_item_visible)
    @user = user
    @user_item_visible = user_item_visible
  end

  class Scope < Scope
    def resolve
      scope.where(user: Current.user)
    end
  end

  def index?
    true
  end

  def destroy?
    owner?
  end

  def create?
    true
  end

  def update?
    owner?
  end

  def move_higher?
    update?
  end

  def move_lower?
    update?
  end

  private

  def owner?
    @user_item_visible.user == Current.user
  end
end
