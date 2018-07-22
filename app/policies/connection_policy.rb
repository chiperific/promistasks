# frozen_string_literal: true

class ConnectionPolicy < ApplicationPolicy
  attr_reader :user, :record

  def index?
    user.staff?
  end

  def show?
    user.staff?
  end

  def new?
    user.staff?
  end

  def create?
    user.staff?
  end

  def edit?
    user.staff?
  end

  def update?
    user.staff?
  end

  def destroy?
    user.staff?
  end

  def discarded?
    user.staff?
  end
end
