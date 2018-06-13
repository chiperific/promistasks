# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaskUser, type: :model do
  before :each do
    stub_request(:any, Constant::Regex::TASKLIST).to_return(
      headers: { 'Content-Type'=> 'application/json' },
      status: 200,
      body: FactoryBot.create(:tasklist_json).marshal_dump.to_json
    )
    stub_request(:any, Constant::Regex::TASK).to_return(
      headers: { 'Content-Type'=> 'application/json' },
      status: 200,
      body: FactoryBot.create(:task_json).marshal_dump.to_json
    )
    @task = FactoryBot.create(:task)
    @user = FactoryBot.create(:oauth_user)
    @task_user = FactoryBot.create(:task_user, task: @task, user: @user)
    WebMock::RequestRegistry.instance.reset!
  end

  describe 'must be valid' do
    let(:no_user) { build :task_user, user_id: nil }
    let(:no_task) { build :task_user, task_id: nil }
    let(:duplicate_gid) { build :task_user }
    let(:deleted_ni) { build :task_user, deleted: nil }

    context 'against the schema' do
      it 'in order to save' do
        expect(@task_user.save!(validate: false)).to eq true

        expect { no_user.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
        expect { no_task.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      end
    end

    context 'against the model' do
      it 'in order to save' do
        expect(@task_user.save!).to eq true

        expect { no_user.save! }.to raise_error ActiveRecord::RecordInvalid
        expect { no_task.save! }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end

  describe 'requires uniqueness' do
    it 'on task and user' do
      @task_user.save

      duplicate = FactoryBot.build(:task_user, task: @task, user: @user)
      expect { duplicate.save!(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
      expect { duplicate.save! }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'on google_id' do
      @task_user.save
      @task.update(title: 'validate')

      duplicate = FactoryBot.build(:task_user, task: @task, google_id: @task_user.google_id)
      expect { duplicate.save!(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
      expect { duplicate.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe 'requires booleans to be in a state' do
    let(:bad_deleted) { build :task_user, deleted: nil }

    it 'deleted' do
      expect { bad_deleted.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { bad_deleted.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe '#assign_from_api_fields!' do
    pending 'returns false if task_json is null'
    pending 'returns false if user isn\'t oauth'
    pending 'returns false if there\'s no google_id'
    pending 'returns false if there\'s no tasklist_gid'
    pending 'uses a json hash to assign record values'
  end

  describe '#api_get' do
    pending 'returns false for non-oauth users'
    pending 'returns false if there\'s no google_id'
    pending 'returns false if there\'s no tasklist_gid'
    pending 'makes an API call'
  end

  describe '#api_insert' do
    pending 'returns false for non-oauth users'
    pending 'returns false if there\'s no google_id'
    pending 'returns false if there\'s no tasklist_gid'
    pending 'makes an API call'
  end

  describe '#api_update' do
    pending 'returns false for non-oauth users'
    pending 'returns false if there\'s no google_id'
    pending 'returns false if there\'s no tasklist_gid'
    pending 'makes an API call'
  end

  describe '#api_delete' do
    pending 'returns false for non-oauth users'
    pending 'returns false if there\'s no google_id'
    pending 'returns false if there\'s no tasklist_gid'
    pending 'makes an API call'
  end

  describe '#api_move' do
    pending 'returns false for non-oauth users'
    pending 'returns false if there\'s no google_id'
    pending 'returns false if there\'s no tasklist_gid'
    pending 'makes an API call'
  end

  describe '#set_position_as_integer' do
    let(:has_position) { build :task_user, task: @task, position: '0000001234' }

    it 'only fires if position is present' do
      expect(@task_user).not_to receive(:set_position_as_integer)
      @task_user.save!

      expect(has_position).to receive(:set_position_as_integer)
      has_position.save!
    end

    it 'sets position_int field based upon position' do
      @task_user.save!
      expect(@task_user.reload.position).to eq nil
      expect(@task_user.position_int).to eq 0

      has_position.save!
      expect(has_position.reload.position).to eq '0000001234'
      expect(has_position.position_int).to eq 1234
    end
  end

  describe '#set_tasklist_gid' do
    let(:no_user) { build :task_user, user_id: nil }
    let(:no_task) { build :task_user, task_id: nil }
    let(:has_tasklist_gid) { build :task_user, tasklist_gid: 'FAKEMDQ5NTUwMTk3NjU1MjE3MTU6MDo1001' }
    let(:fresh) { build :task_user }

    it 'returns false if user is nil' do
      expect(no_user.send(:set_tasklist_gid)).to eq false
    end

    it 'returns false if task is nil' do
      expect(no_task.send(:set_tasklist_gid)).to eq false
    end

    it 'only fires if tasklist_gid is empty' do
      expect(has_tasklist_gid).not_to receive(:set_tasklist_gid)
      has_tasklist_gid.save!
    end

    it 'sets the tasklist_gid from the parent property' do
      expect(fresh).to receive(:set_tasklist_gid)
      fresh.save!
    end
  end

  describe '#elevate_completeness' do
    let(:completed) { build :task_user, completed_at: Time.now - 1.hour }
    let(:complete_task) { build :task, completed_at: Time.now }

    it 'only fires if completed_at is present and the task isn\'t marked complete' do
      # task_user completed_at set, but not task
      expect(completed).to receive(:elevate_completeness)
      completed.save!

      # neither completed_at set
      expect(@task_user).not_to receive(:elevate_completeness)
      @task_user.save!

      # both completed_at set
      completed.update(task: complete_task)
      expect(completed).not_to receive(:elevate_completeness)
      completed.save!

      # task completed_at set, but not task_user
      @task.update(completed_at: Time.now)
      expect(@task_user).not_to receive(:elevate_completeness)
      @task_user.save!
    end

    it 'sets the parent task\'s completed_at to match' do
      time = completed.completed_at
      task = completed.task
      completed.save!
      expect(task.completed_at).to eq time
    end
  end
end
