# frozen_string_literal: true

class MessageObjectPolicy < ApplicationPolicy
  attr_reader :user, :message_object

  def initialize(user, message_object)
    @user = user
    @message_object = message_object
  end

  class Scope < Scope
    def resolve
      scope.all if @user.site_admin?

      scope.where(
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

  def destroy?
    @message_object.message.is_a?(MessageDraft)
  end
end
