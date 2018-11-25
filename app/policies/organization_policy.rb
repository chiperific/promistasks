# frozen_string_literal: true

class OrganizationPolicy < ApplicationPolicy
  # attr_reader :user, :record

  class Scope < Scope
    def resolve
      scope
    end
  end

  def show?
    user&.admin?
  end

  def edit?
    user&.admin?
  end

  def update?
    user&.admin?
  end
end
