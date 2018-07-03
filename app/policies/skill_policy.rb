# frozen_string_literal: true

class SkillPolicy < ApplicationPolicy
  attr_reader :user, :property

  def index?
    user&.staff?
  end

  def show?
    user&.staff?
  end

  def new?
    user&.staff?
  end

  def create?
    user&.staff?
  end

  def edit?
    user&.staff?
  end

  def update?
    user&.staff?
  end

  def destroy?
    user&.staff?
  end
end
