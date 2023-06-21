# frozen_string_literal: true

class FolderPolicy < ApplicationPolicy
  attr_reader :user, :folder

  def initialize(user, folder)
    @user = user
    @folder = folder
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
