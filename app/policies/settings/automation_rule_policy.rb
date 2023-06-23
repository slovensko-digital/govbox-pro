class Settings::AutomationRulePolicy < ApplicationPolicy
  attr_reader :user, :automation_rule

  def initialize(user, automation_rule)
    @user = user
    @automation_rule = automation_rule
  end

  class Scope < Scope
    def resolve
      scope.where(tenant_id: @user.tenant_id, user: @user)
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
