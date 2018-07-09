# frozen_string_literal: true

class TaskPolicy < ApplicationPolicy
  attr_reader :user, :record

  def public?
    true
  end

  def index?
    user&.staff?
  end

  def show?
    record.visible_to?(user)
  end

  def new?
    user&.staff?
  end

  def create?
    user&.staff?
  end

  def edit?
    user&.staff?
  end

  def destroy?
    user&.staff?
  end

  def complete?
    record.visible_to?(user) || user.system_admin?
  end

  def un_complete?
    record.visible_to?(user) || user.system_admin?
  end
end
