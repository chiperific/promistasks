# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  attr_reader :user, :record

  def index?
    user&.system_admin?
  end

  def show?
    user&.system_admin? || user == record
  end

  def new?
    user&.system_admin?
  end

  def create?
    user&.system_admin?
  end

  def edit?
    user&.system_admin? || user == record
  end

  def destroy?
    user&.system_admin?
  end
end
