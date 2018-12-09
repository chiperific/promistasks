# frozen_string_literal: true

class UtilityPolicy < ApplicationPolicy
  attr_reader :user, :record

  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    user&.staff? || user&.admin?
  end

  def show?
    user&.staff? || user&.admin?
  end

  def new?
    user&.staff? || user&.admin?
  end

  def create?
    user&.staff? || user&.admin?
  end

  def edit?
    user&.staff? || user&.admin?
  end

  def update?
    user&.staff? || user&.admin?
  end
end
