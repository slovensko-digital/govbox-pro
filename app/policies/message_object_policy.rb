# frozen_string_literal: true

class MessageObjectPolicy < ApplicationPolicy
  attr_reader :user, :message_object

  def initialize(user, message_object)
    @user = user
    @message_object = message_object
  end

  class Scope < Scope
    def resolve
      @user.site_admin? ? scope.all : scope.where(tenant_id: @user.tenant_id)
    end
  end

  def show?
    true
  end

  def download?
    true
  end
end
