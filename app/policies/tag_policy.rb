# frozen_string_literal: true

class TagPolicy < ApplicationPolicy
  attr_reader :user, :tag

  def initialize(user, tag)
    @user = user
    @tag = tag
  end

  class Scope < Scope
    def resolve
      return scope.where(tenant: Current.tenant) if @user.site_admin?
      return scope.where(tenant: @user.tenant) if @user.admin?

      scope.where(
        TagGroup
          .select(1)
          .joins(:group_memberships)
          .where("tag_groups.tag_id = tags.id")
          .where(group_memberships: { user_id: @user.id })
          .arel.exists
      )
    end
  end

  class ScopeListable < Scope
    def resolve
      scope.where(tenant: Current.tenant)
    end
  end
end
