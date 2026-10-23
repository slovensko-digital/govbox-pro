# frozen_string_literal: true

class UserFilterVisibilityPolicy < ApplicationPolicy
  def create?
    true
  end

  def update?
    record.user_id == user.id && record.filter.tenant_id == user.tenant_id &&
      (record.filter.common? || record.filter.author_id == user.id)
  end

  alias_method :move_higher?, :update?
  alias_method :move_lower?, :update?
end
