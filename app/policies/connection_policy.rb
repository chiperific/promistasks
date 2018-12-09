# frozen_string_literal: true

class ConnectionPolicy < ApplicationPolicy
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
end
