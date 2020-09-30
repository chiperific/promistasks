# frozen_string_literal: true

class TasklistPolicy < ApplicationPolicy
  attr_reader :user, :record

  def push?
    user == record.user
  end
end
