# frozen_string_literal: true

class ParkUserPolicy < ApplicationPolicy
  attr_reader :user, :record

  def index?
    user.staff? || user.admin?
  end

  def new?
    user.staff? || user.admin?
  end

  def create?
    user.staff? || user.admin?
  end

  def edit?
    user.staff? || user.admin?
  end

  def update?
    user.staff? || user.admin?
  end

  def destroy?
    user.staff? || user.admin?
  end
end
