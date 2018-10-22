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
end
