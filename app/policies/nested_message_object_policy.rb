# frozen_string_literal: true

class NestedMessageObjectPolicy < ApplicationPolicy
  attr_reader :user, :nested_message_object

  def initialize(user, nested_message_object)
    @user = user
    @nested_message_object = nested_message_object
  end

  class Scope < Scope
    def resolve
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

  def download_pdf?
    true
  end
end
