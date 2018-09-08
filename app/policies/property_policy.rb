# frozen_string_literal: true

class PropertyPolicy < ApplicationPolicy
  attr_reader :user, :record

  def index?
    user&.staff? || user&.admin?
  end

  def list?
    user&.staff? || user&.admin?
  end

  def show?
    user&.staff? || user&.admin? || record.visible_to?(user)
  end

  def new?
    user&.staff? || user&.admin?
  end

  def create?
    user&.staff? || user&.admin?
  end

  def edit?
    user&.staff? || user&.admin? || record.visible_to?(user)
  end

  def update?
    user&.staff? || user&.admin? || record.visible_to?(user)
  end

  def default?
    user&.staff? || user&.admin?
  end

  def reports?
    user&.staff? || user&.admin?
  end

  def tasks_filter?
    user&.not_client?
  end

  def property_enum?
    user&.not_client?
  end
end
