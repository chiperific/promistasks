# frozen_string_literal: true

class SkillUser < ApplicationRecord
  include Discard::Model

  belongs_to :skill, inverse_of: :skill_users
  belongs_to :user, inverse_of: :skill_users

  validates_presence_of :skill, :user

  validates_inclusion_of :is_licensed, in: [true, false]
end
