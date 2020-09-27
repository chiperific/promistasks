# frozen_string_literal: true

class TasklistPolicy < ApplicationPolicy
  attr_reader :user, :record

  def create?
    user
  end

  def destroy?
    show
  end
end
