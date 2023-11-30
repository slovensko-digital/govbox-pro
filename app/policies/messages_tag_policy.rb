# frozen_string_literal: true

class MessagesTagPolicy < ApplicationPolicy
  attr_reader :user, :messages_tag

  def initialize(user, messages_tag)
    @user = user
    @messages_tag = messages_tag
  end

  class Scope < Scope
    def resolve
      if @user.admin?
        return scope.where(
          MessagesTag
            .joins({ message: { thread: :box } }, :tag)
            .where(box: { tenant_id: Current.tenant.id })
            .where(tag: { tenant_id: Current.tenant.id })
            .arel.exists
        )
      end

      scope.joins(:message, :tag).where(message: Pundit.policy_scope(user, Message), tag: Pundit.policy_scope(user, Tag))
    end
  end

  def create?
    return false unless Pundit.policy_scope(user, Message).find_by(id: @messages_tag.message_id)
    return false unless @messages_tag.tag.tenant == Current.tenant

    true
  end

  def destroy?
    return false unless @messages_tag
    return false unless Pundit.policy_scope(user, Message).find_by(id: @messages_tag.message_id)
    return false unless Pundit.policy_scope(user, Tag).find_by(id: @messages_tag.tag_id)
    return false unless @messages_tag.tag.tenant == Current.tenant

    true
  end
end
