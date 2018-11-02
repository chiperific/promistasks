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
end
