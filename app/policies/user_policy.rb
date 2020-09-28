# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  attr_reader :user, :record

  def show?
    user.present?
  end

  def destroy?
    user
  end
end
