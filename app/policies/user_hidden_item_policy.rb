# frozen_string_literal: true

class UserHiddenItemPolicy < ApplicationPolicy
  attr_reader :user, :user_hidden_item

  def initialize(user, user_hidden_item)
    @user = user
    @user_hidden_item = user_hidden_item
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
    @user_hidden_item.user == Current.user
  end

  def create?
    true
  end
end
