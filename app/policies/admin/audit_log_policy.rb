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
    Current.tenant.feature_enabled?(:audit_log) && @user.admin?
  end

  def scroll?
    Current.tenant.feature_enabled?(:audit_log) && index?
  end
end
