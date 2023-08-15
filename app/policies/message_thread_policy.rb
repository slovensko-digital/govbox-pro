# frozen_string_literal: true

class MessageThreadPolicy < ApplicationPolicy
  attr_reader :user, :message_thread

  def initialize(user, message_thread)
    @user = user
    @message_thread = message_thread
  end

  class Scope < Scope
    def resolve
      if @user.site_admin?
        scope.all
      else
        scope.joins(tags: { groups: :group_memberships }).where(group_memberships: { user_id: @user.id })
      end
    end
  end

  def show?
    true
  end

  def index?
    true
  end

  def update?
    true
  end

  def merge?
    true
  end
end
