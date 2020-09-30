# frozen_string_literal: true

class AutoTaskPolicy < ApplicationPolicy
  attr_reader :user, :record

  def create?
    user
  end

  def edit?
    user == record.user
  end

  def update?
    edit?
  end

  def destroy?
    edit?
  end

  def reposition?
    AutoTask.where(id: record).pluck(:user_id).uniq[0] == user.id
  end
end
