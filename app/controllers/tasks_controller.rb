# frozen_string_literal: true

class TasksController < ApplicationController
  def public
    @tasks = Task.public_visible.present? ? Task.public_visible : 'No tasks found'
  end
end
