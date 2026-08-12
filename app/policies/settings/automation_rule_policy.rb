class Settings::AutomationRulePolicy < ApplicationPolicy
  attr_reader :user, :automation_rule

  def initialize(user, automation_rule)
    @user = user
    @automation_rule = automation_rule
  end

  class Scope < Scope
    def resolve
      if @user.admin?
        scope.where(tenant: Current.tenant)
      else
        scope.where(tenant: Current.tenant, user: @user)
      end
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
    @user.admin?
  end

  def update?
    @user.admin?
  end

  def edit?
    @user.admin?
  end

  def header_step?
    @user.admin?
  end

  def conditions_step?
    @user.admin?
  end

  def actions_step?
    @user.admin?
  end

  def edit_form?
    @user.admin?
  end

  def destroy?
    @user.admin?
  end

  def rerender?
    @user.admin?
  end
end
