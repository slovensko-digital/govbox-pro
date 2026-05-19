class Admin::BoxGroupPolicy < ApplicationPolicy
  attr_reader :user, :box_group

  def initialize(user, box_group)
    @user = user
    @box_group = box_group
  end

  class Scope < Scope
    def resolve
      scope.joins(:box, :group)
           .where(boxes: { tenant: @user.tenant })
           .where(groups: { tenant: @user.tenant })
    end
  end

  def create?
    return false unless @user.admin?
    return false unless @box_group.box.tenant == @user.tenant
    return false unless @box_group.group.tenant == @user.tenant

    true
  end

  def destroy?
    create?
  end
end
