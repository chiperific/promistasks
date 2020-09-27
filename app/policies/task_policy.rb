# frozen_string_literal: true

class TaskPolicy < ApplicationPolicy
  attr_reader :user, :record

  def create?
    user
  end

  def update?
    show
  end

  def destroy?
    show
  end
end
