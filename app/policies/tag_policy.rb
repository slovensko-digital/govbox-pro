# frozen_string_literal: true

class TagPolicy < ApplicationPolicy
  attr_reader :user, :tag

  def initialize(user, tag)
    @user = user
    @tag = tag
  end

  class Scope < Scope
    def resolve
      @user.site_admin? ? scope.all : scope.where(tenant_id: @user.tenant_id)
    end
  end

  def show?
    true
  end

end
