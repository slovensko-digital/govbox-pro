class Admin::BoxGroupPolicy < ApplicationPolicy
  attr_reader :user, :box_group

  def initialize(user, box_group)
    @user = user
    @box_group = box_group
  end

  def create?
    return false unless @user.admin?
    return false unless @box_group.box.tenant == Current.tenant
    return false unless @box_group.group.tenant == Current.tenant

    true
  end

  def destroy?
    @user.admin?
  end
end
