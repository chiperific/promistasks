# frozen_string_literal: true

class UtilityPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end
end
