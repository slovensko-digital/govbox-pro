# frozen_string_literal: true

class TagPolicy < ApplicationPolicy
  attr_reader :user, :tag

  def initialize(user, tag)
    @user = user
    @tag = tag
  end

  class Scope < Scope
    def resolve
      return scope.where(tenant_id: Current.tenant.id) if @user.site_admin?
      return scope.where(tenant_id: @user.tenant_id) if @user.admin?

      scope.where('id IN (
        SELECT tag_id FROM tag_groups tg
        JOIN group_memberships gm on tg.group_id = gm.group_id
        WHERE gm.user_id = ?
      )', @user.id)
    end
  end

  def show?
    true
  end
end
