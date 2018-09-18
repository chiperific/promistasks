# frozen_string_literal: true

class ParkPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def index?
    user&.staff? || user&.admin?
  end

  def list?
    user&.staff? || user&.admin?
  end

  def show?
    user&.can_view_park(record)
  end

  def new?
    user&.staff? || user&.admin?
  end

  def edit?
    user&.staff? || user&.admin?
  end

  def create?
    user&.staff? || user&.admin?
  end

  def update?
    user&.staff? || user&.admin?
  end

  def properties_filter?
    user&.can_view_park(record)
  end

  def users?
    user&.staff? || user&.admin?
  end
end
