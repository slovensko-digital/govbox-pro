# frozen_string_literal: true

class Admin::ApiAccessPolicy < ApplicationPolicy
  attr_reader :user, :tenant

  def initialize(user, tenant)
    @user = user
    @tenant = tenant
  end

  class Scope < Scope
    def resolve
      Tenant.where(id: @user.tenant)
    end
  end

  def show?
    @user.admin?
  end

  def update?
    @user.admin?
  end
end
