# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  attr_reader :user, :record

  def show?
    user == record
  end

  def destroy?
    show?
  end

  def authorization?
    show?
  end
end
