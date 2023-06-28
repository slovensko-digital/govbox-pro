# frozen_string_literal: true

class MessagePolicy < ApplicationPolicy
  attr_reader :user, :message

  def initialize(user, message)
    @user = user
    @message = message
  end

  class Scope < Scope
    def resolve
      @user.site_admin? ? scope.all : scope.where(tenant_id: @user.tenant_id)
    end
  end

  def show?
    true
  end

  def reply?
    true # TODO can everyone reply?
  end

  def submit_reply?
    reply?
  end
end
