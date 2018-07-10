# frozen_string_literal: true

class TaskPolicy < ApplicationPolicy
  attr_reader :user, :record

  def public?
    true
  end

  def index?
    user&.not_client?
  end

  def show?
    record.visible_to?(user)
  end

  def new?
    user&.not_client?
  end

  def create?
    user&.not_client?
  end

  def edit?
    user&.not_client?
  end

  def update?
    user&.not_client?
  end

  def destroy?
    user&.staff?
  end
end
