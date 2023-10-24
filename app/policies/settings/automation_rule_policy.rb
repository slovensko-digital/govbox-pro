class Settings::AutomationRulePolicy < ApplicationPolicy
  attr_reader :user, :automation_rule

  def initialize(user, automation_rule)
    @user = user
    @automation_rule = automation_rule
  end

  class Scope < Scope
    def resolve
      if @user.admin? || @user.site_admin?
        scope.where(tenant: Current.tenant)
      else
        scope.where(tenant: Current.tenant, user: @user)
      end
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

  def header_step?
    true
  end

  def conditions_step?
    true
  end

  def actions_step?
    true
  end

  def edit_form?
    true
  end

  def destroy?
    true
  end

  def rerender?
    true
  end
end
