# frozen_string_literal: true

class PropertyPolicy < ApplicationPolicy
  attr_reader :user, :record

  def index?
    user&.staff?
  end

  def list?
    user&.staff?
  end

  def show?
    user&.staff? && record.visible_to?(user)
  end

  def new?
    user&.staff?
  end

  def create?
    user&.staff?
  end

  def edit?
    user&.staff? || record.visible_to?(user)
  end

  def update?
    user&.staff? || record.visible_to?(user)
  end

  def default?
    user&.staff?
  end

  def reports?
    user&.staff?
  end

  def tasks_filter?
    user&.not_client?
  end

  def property_enum?
    user&.not_client?
  end
end
