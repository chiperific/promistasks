# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  attr_reader :user, :record

  def show?
    record == user
  end

  def create?
    true
  end

  def destroy?
    show
  end

  def in?
    create
  end

  def oauth?
    create
  end

  def out?
    true
  end
end
