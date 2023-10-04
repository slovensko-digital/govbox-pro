# frozen_string_literal: true

class BoxPolicy < ApplicationPolicy
  attr_reader :user, :box

  def initialize(user, box)
    @user = user
    @box = box
  end

  class Scope < Scope
    def resolve
      @user.site_admin? ? scope.all : scope.where(tenant: @user.tenant)
    end
  end

  def index?
    @user.site_admin? || @user.admin?
  end

  def show?
    @user.site_admin? || @user.admin?
  end

  def sync?
    @user.site_admin? || @user.admin?
  end

  def select?
    true
  end

  def select_all?
    true
  end

  def search?
    true
  end

  def get_selector?
    true
  end

end
