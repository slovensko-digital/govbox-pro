# frozen_string_literal: true

class GroupMembershipPolicy < ApplicationPolicy
  attr_reader :user, :group_membership

  def initialize(user, group_membership)
    @user = user
    @siteadmin = (@user.user_type == 'SITE_ADMIN')
    @admin = @user.groups.exists?(group_type: 'ADMIN')
  end

  class Scope < Scope
    def resolve
      if @siteadmin
        scope.all
      else
        scope.includes(:user).where('user.tenant_id = ?', @user.tenant_id).includes(:group).where('group.tenant_id = ?', @user.tenant_id)
      end
    end
  end

   def index
    @siteadmin || @admin
  end

  def show?
    @siteadmin || @admin
  end

  def create?
    @siteadmin || @admin
  end

  def new?
    create?
  end

  def update?
    @siteadmin || @admin
  end

  def edit?
    update?
  end

  def destroy?
    @siteadmin || @admin
  end

end
