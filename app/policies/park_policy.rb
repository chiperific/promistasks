# frozen_string_literal: true

class ParkPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end
end
