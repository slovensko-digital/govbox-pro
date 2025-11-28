# frozen_string_literal: true

class BoxPolicy < ApplicationPolicy
  attr_reader :user, :box

  def initialize(user, box)
    @user = user
    @box = box
  end

  class Scope < Scope
    def resolve
      @user.accessible_boxes
    end
  end

  def index?
    @user.admin?
  end

  def show?
    @user.admin?
  end

  def sync?
    @user.admin?
  end

  def sync_all?
    true
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
