class Settings::AutomationConditionPolicy < ApplicationPolicy
  attr_reader :user, :automation_condition

  def initialize(user, automation_condition)
    @user = user
    @automation_condition = automation_condition
  end

  class Scope < Scope
    def resolve
      scope.joins(:automation_rule).where(automation_rule: {user_id: @user.id})
    end
  end

  def index?
    true
  end

  def show?
    true
  end

  def create?
    true
  end

  def new?
    true
  end

  def update?
    true
  end

  def edit?
    true
  end

  def destroy?
    true
  end
end
