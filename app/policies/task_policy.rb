# frozen_string_literal: true

class TaskPolicy < ApplicationPolicy
  attr_reader :user, :record

  def public?
    true
  end

  def index?
    user&.not_client?
  end

  def admin?
    user&.system_admin?
  end

  def show?
    record.visible_to?(user)
  end

  def skills?
    record.related_to?(user) || user.staff?
  end

  def update_skills?
    record.related_to?(user) || user.staff?
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

  def complete?
    record.related_to?(user) || user.staff?
  end

  def un_complete?
    record.related_to?(user) || user.staff?
  end
end
