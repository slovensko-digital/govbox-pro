# frozen_string_literal: true

class TenantPolicy < ApplicationPolicy
  attr_reader :user, :tenant

  def initialize(user, tenant)
    @user = user
    @siteadmin = (@user.user_type == 'SITE_ADMIN')
    @tenant = tenant
  end

  class Scope < Scope
    def resolve
      if @siteadmin
        scope.all
      else
        scope.where(id: @user.tenant_id)
      end
    end
  end

   def index?
    true
    #@siteadmin
  end

  def show?
    true
    #@siteadmin || @user.tenant_id == @tenant.id
  end

  def create?
    @siteadmin
  end

  def new?
    create?
  end

  def update?
    @siteadmin
  end

  def edit?
    update?
  end

  def destroy?
    @siteadmin
  end

end
