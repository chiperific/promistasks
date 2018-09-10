# frozen_string_literal: true

class TaskPolicy < ApplicationPolicy
  attr_reader :user, :record

  def index?
    user&.not_client?
  end

  def show?
    user.present? && record.visible_to?(user)
  end

  def public?
    true
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

  def public_index?
    true
  end

  def users_finder?
    record.related_to?(user) || user.staff?
  end

  def complete?
    record.related_to?(user) || user.staff?
  end

  def un_complete?
    record.related_to?(user) || user.staff?
  end
end
