# frozen_string_literal: true

class OrganizationPolicy < ApplicationPolicy
  attr_reader :user, :record

  def show?
    user.admin?
  end

  def edit?
    user.admin?
  end
end
