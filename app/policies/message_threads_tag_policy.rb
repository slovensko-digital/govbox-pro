# frozen_string_literal: true

class MessageThreadsTagPolicy < ApplicationPolicy
  attr_reader :user, :message_threads_tag

  def initialize(user, message_threads_tag)
    @user = user
    @message_threads_tag = message_threads_tag
  end

  class Scope < Scope
    def resolve
      return scope.all if @user.site_admin?

      scope.where(
        Tag
          .select(1)
          .where("tags.id = message_threads_tags.tag_id")
          .where(tags: { tenant_id: @user.tenant_id })
          .arel.exists
      )
    end
  end

  def index
    true
  end

  def show?
    true
  end

  def create?
    true
  end

  def new?
    create?
  end

  def update?
    true
  end

  def edit?
    update?
  end

  def destroy?
    true
  end

  def prepare?
    true
  end
end

