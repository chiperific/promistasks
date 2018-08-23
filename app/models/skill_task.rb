# frozen_string_literal: true

class SkillTask < ApplicationRecord
  belongs_to :task, inverse_of: :skill_tasks
  belongs_to :skill, inverse_of: :skill_tasks

  validates_presence_of :task, :skill
end
