# frozen_string_literal: true

class SkillPolicy < ApplicationPolicy
  attr_reader :user, :property

  def index?
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

  def users?
    user&.staff? || user&.admin?
  end

  def update_users?
    user&.staff? || user&.admin?
  end

  def tasks?
    user&.staff? || user&.admin?
  end

  def update_tasks?
    user&.staff? || user&.admin?
  end
end
