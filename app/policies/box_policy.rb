# frozen_string_literal: true

class BoxPolicy < ApplicationPolicy
  attr_reader :user, :box

  def initialize(user, box)
    @user = user
    @box = box
  end

  class Scope < Scope
    def resolve
      @user.site_admin? ? scope.all : scope.where(tenant_id: @user.tenant_id)
    end
  end

  def index?
    true
  end

  def show?
    @user.site_admin? || @user.admin? || @box.tenant_id == @user.tenant_id
  end

  def sync?
    show?
  end
end
