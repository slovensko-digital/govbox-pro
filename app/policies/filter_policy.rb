# frozen_string_literal: true

class FilterPolicy < ApplicationPolicy
  attr_reader :user, :filter

  def initialize(user, filter)
    @user = user
    @filter = filter
  end

  class ScopeEditable < Scope
    def resolve
      scoped = scope.where(tenant_id: Current.tenant).visible_for(@user)

      return scoped if @user.admin?

      scoped.where(author_id: @user.id)
    end
  end

  class ScopeShowable < Scope
    def resolve
      scoped = scope.where(tenant_id: Current.tenant)

      return scoped if @user.admin?

      scoped.left_joins(:tag)
        .where(
          TagGroup
            .select(1)
            .joins(:group_memberships)
            .where("tag_groups.tag_id = tags.id")
            .where(group_memberships: { user_id: @user.id })
            .arel.exists)
        .or(scoped.where(author_id: [nil, @user.id]))
    end
  end

  def index?
    true
  end

  def new?
    true
  end

  def create?
    true
  end

  def edit?
    @user.admin? || is_author_current_user?
  end

  def update?
    @user.admin? || is_author_current_user?
  end

  def destroy?
    @user.admin? || is_author_current_user?
  end

  def pin?
    is_author_current_user?
  end

  def unpin?
    pin?
  end

  def sort?
    is_author_current_user?
  end

  private

  def is_author_current_user?
    @filter.author == @user
  end
end
