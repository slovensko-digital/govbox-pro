# frozen_string_literal: true

class MessageTemplatePolicy < ApplicationPolicy
  attr_reader :user, :message_template

  def initialize(user, message_template)
    @user = user
    @message_template = message_template
  end

  class Scope < Scope
    def resolve
      return scope.where(tenant: Current.tenant).or(scope.where(tenant: nil)) if @user.site_admin?
      scope.where(tenant: @user.tenant).or(scope.where(tenant: nil))
    end
  end

  def recipients_list?
    true
  end
end
