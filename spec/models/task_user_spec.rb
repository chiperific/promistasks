# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaskUser, type: :model do
  describe 'must be valid' do
    pending 'in order to save'
  end

  describe 'requires uniqueness' do
    pending 'on task and user'
    pending 'on google_id'
  end

  describe '#set_position_as_integer' do
    let(:has_position) { build :task_user, position: '0000001234'}

    it 'only fires if position is present' do
      expect(@task).not_to receive(:copy_position_as_integer)
      @task.save!

      expect(has_position).to receive(:copy_position_as_integer)
      has_position.save!
    end

    it 'sets position_int field based upon position' do
      @task.save!
      expect(@task.reload.position).to eq nil
      expect(@task.position_int).to eq 0

      has_position.save!
      expect(has_position.reload.position).to eq '0000001234'
      expect(has_position.position_int).to eq 1234
    end
  end

  describe '#set_tasklist_id' do
    pending 'only fires if tasklist_id is empty'
    pending 'sets the tasklist_id from the parent property'
  end
end
