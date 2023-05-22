# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  attr_reader :user

  def initialize(user_logged_in, user_to_authorize)
    @user = user_logged_in
    @siteadmin = (@user.user_type == 'SITE_ADMIN')
    @admin = @user.groups.exists?(group_type: 'ADMIN')
  end

  class Scope < Scope
    def resolve
      if @siteadmin
        scope.all
      else
        scope.where(tenant_id: @user.tenant_id)
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
