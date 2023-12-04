# frozen_string_literal: true

class Admin::AuditLogPolicy < ApplicationPolicy
  attr_reader :user, :audit_log

  def initialize(user, audit_log)
    @user = user
    @audit_log = audit_log
  end

  class Scope < Scope
    def resolve
      scope.where(tenant: @user.tenant)
    end
  end

  def index?
    return false unless Current.tenant.feature_enabled?(:audit_log)
    return false unless @user.admin?

    true
  end

  def scroll?
    index?
  end
end
