# frozen_string_literal: true

class MessageThreadPolicy < ApplicationPolicy
  attr_reader :user, :message_thread

  def initialize(user, message_thread)
    @user = user
    @message_thread = message_thread
  end

  class Scope < Scope
    def resolve
      @user.site_admin? ? scope.all : scope.where(tenant_id: @user.tenant_id)
    end
  end

  def show?
    true
  end

end
