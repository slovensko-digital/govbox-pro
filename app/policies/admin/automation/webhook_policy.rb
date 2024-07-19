# frozen_string_literal: true

class Admin::Automation::WebhookPolicy < ApplicationPolicy
  attr_reader :user, :webhook

  def initialize(user, webhook)
    @user = user
    @webhook = webhook
  end

  class Scope < Scope
    def resolve
      scope.where(tenant: @user.tenant)
    end
  end

  def index?
    @user.admin?
  end

  def destroy?
    @user.admin?
  end

  def show?
    @user.admin?
  end

  def create?
    @user.admin?
  end

  def new?
    create?
  end

  def update?
    @user.admin?
  end

  def edit?
    update?
  end
end
