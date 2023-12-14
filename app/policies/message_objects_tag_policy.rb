class MessageObjectsTagPolicy < ApplicationPolicy
  attr_reader :user, :message_objects_tag

  def edit?
    true
  end

  def prepare?
    true
  end

  def update?
    true
  end
end
