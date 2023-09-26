# frozen_string_literal: true

class FilterPolicy < ApplicationPolicy
  attr_reader :user, :filter

  def initialize(user, filter)
    @user = user
    @filter = filter
  end

  class Scope < Scope
    def resolve
      scope.where(user_id: @user.id)
    end
  end

  def index?
    true
  end

  def new?
    true
  end

  def create?
    true
  end

  def edit?
    true
  end

  def update?
    true
  end

  def destroy?
    true
  end
end
