# frozen_string_literal: true

class UserFilterVisibilityPolicy < ApplicationPolicy
  attr_reader :user, :user_filter_visibility

  def initialize(user, user_filter_visibility)
    @user = user
    @user_filter_visibility = user_filter_visibility
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
    @user_filter_visibility.user == Current.user
  end
end
