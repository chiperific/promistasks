# frozen_string_literal: true

class Skill < ApplicationRecord
  include Discard::Model

  has_many :skill_tasks, inverse_of: :skill, dependent: :destroy
  has_many :tasks, through: :skill_tasks
  accepts_nested_attributes_for :skill_tasks, allow_destroy: true

  has_many :skill_users, inverse_of: :skill, dependent: :destroy
  has_many :users, through: :skill_users
  accepts_nested_attributes_for :skill_users, allow_destroy: true

  validates :name, uniqueness: true, presence: true
  validates_inclusion_of :volunteerable, :license_required, in: [true, false]

  scope :active, -> { kept }
end
