# frozen_string_literal: true

class DraftPolicy < ApplicationPolicy
  attr_reader :user, :draft

  def initialize(user, draft)
    @user = user
    @draft = draft
  end

  class Scope < Scope
    def resolve
      @user.site_admin? ? scope.all : scope.where(box: Current.box)
    end
  end

  def index?
    true
  end

  def show?
    @user.tenant == @draft.box.tenant && @draft.box == Current.box
  end

  def destroy?
    @user.tenant == @draft.box.tenant && @draft.box == Current.box
  end

  def submit?
    @user.tenant == @draft.box.tenant && @draft.box == Current.box
  end

  def submit_all?
    @user.tenant == @draft.box.tenant && @draft.box == Current.box
  end
end
