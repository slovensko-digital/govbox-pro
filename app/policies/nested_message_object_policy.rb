# frozen_string_literal: true

class NestedMessageObjectPolicy < ApplicationPolicy
  attr_reader :user, :nested_message_object

  def initialize(user, nested_message_object)
    @user = user
    @nested_message_object = nested_message_object
  end

  class Scope < Scope
    def resolve
      if @user.admin?
        return scope.where(
          NestedMessageObject
            .joins(message_object: { message: { thread: :box } })
            .where(box: { tenant_id: Current.tenant.id })
            .arel.exists
        )
      end
      scope.joins(:message_object).where(
        Message
          .select(1)
          .joins(message_threads_tags: { tag_groups: :group_memberships })
          .where("message_objects.message_id = messages.id")
          .where(group_memberships: { user_id: @user.id })
          .arel.exists
      )
    end
  end

  def show?
    true
  end

  def download?
    true
  end
end
