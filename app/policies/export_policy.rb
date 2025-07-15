# frozen_string_literal: true

class ExportPolicy < ApplicationPolicy
  attr_reader :user, :export

  def initialize(user, export)
    @user = user
    @export = export
  end

  class Scope < Scope
    def resolve
      scope.where(user: @user)
    end
  end

  def show?
    true
  end

  def edit?
    true
  end

  def update?
    true
  end

  def start?
    true
  end
end
