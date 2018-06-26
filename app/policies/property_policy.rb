# frozen_string_literal: true

class PropertyPolicy < ApplicationPolicy
  attr_reader :user, :property

  def index?
    user&.staff?
  end

  def show?
    user&.staff? && property.can_be_viewed_by(user)
  end

  def new?
    user&.staff?
  end

  def create?
    user&.staff?
  end

  def edit?
    user&.staff? && property.can_be_viewed_by(user)
  end

  def destroy?
    user&.staff? && property.can_be_viewed_by(user)
  end

  def reports?
    user&.staff?
  end

  def discarded?
    user&.staff?
  end
end
