# frozen_string_literal: true

class ConnectionPolicy < ApplicationPolicy
  attr_reader :user, :record

  def new?
    user.staff?
  end

  def create?
    user.staff?
  end

  def edit?
    user.staff? || user == record.user
  end

  def update?
    user.staff? || user == record.user
  end

  def destroy?
    user.staff? || user == record.user
  end

  def discarded?
    user.staff?
  end
end
