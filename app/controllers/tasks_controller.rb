# frozen_string_literal: true

class TasksController < ApplicationController
  def public
    props = Property.public_visible
    tasks = props.tasks.public_visible if props.present?
    @tasks = tasks || 'No tasks found'
  end
end
