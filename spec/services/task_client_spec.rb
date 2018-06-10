# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaskClient, type: :service do
  describe '#list' do
    pending 'returns all tasks in the specified tasklist'
  end

  describe '#get' do
    pending 'returns a specific task in the specified tasklist'
  end

  describe '#insert' do
    pending 'adds a task to the specified tasklist'
  end

  describe '#update' do
    pending 'updates a task in the specified tasklist'
  end

  describe '#delete' do
    pending 'deletes a task from the specified tasklist'
  end

  describe '#clear_complete' do
    pending 'clears all completed tasks from the specified tasklist'
  end

  describe '#move' do
    pending 'moves a task to another position in the specified tasklist'
  end

  describe '#relocate' do
    pending 'moves a task to another tasklist'
  end
end
