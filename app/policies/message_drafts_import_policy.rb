# frozen_string_literal: true

class MessageDraftsImportPolicy < ApplicationPolicy
  attr_reader :user

  def initialize(user, _)
    @user = user
  end

  def create?
    true # TODO decide according to user rights
  end

  def upload_new?
    create?
  end
end
