# frozen_string_literal: true

class PropertyPolicy < ApplicationPolicy
  attr_reader :user, :record

  def index?
    user&.staff?
  end

  def show?
    user&.staff? && record.can_be_viewed_by(user)
  end

  def new?
    user&.staff?
  end

  def create?
    user&.staff?
  end

  def edit?
    user&.staff? || record.can_be_viewed_by(user)
  end

  def update?
    user&.staff? || record.can_be_viewed_by(user)
  end

  def destroy?
    user&.staff? || record.can_be_viewed_by(user)
  end

  def default?
    user&.staff?
  end

  def reports?
    user&.staff?
  end

  def discarded?
    user&.staff?
  end
end
