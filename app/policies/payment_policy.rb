# frozen_string_literal: true

class PaymentPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    user&.staff? || user&.admin?
  end

  def history?
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
