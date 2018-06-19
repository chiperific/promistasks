# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaskUser, type: :model do
  before :each do
    @user = FactoryBot.create(:oauth_user)
    @property = FactoryBot.create(:property, creator: @user)
    @task = FactoryBot.create(:task, property: @property, creator: @user, owner: @user)
    @task_user = @task.task_users.where(user: @user).first
    WebMock.reset_executed_requests!
  end

  describe 'must be valid' do
    let(:no_user) { build :task_user, user_id: nil }
    let(:no_task) { build :task_user, task_id: nil }
    let(:duplicate_gid) { build :task_user }
    let(:deleted_ni) { build :task_user, deleted: nil }
    let(:no_tasklist_gid) { create :task_user }

    context 'against the schema' do
      it 'in order to save' do
        expect(@task_user.save!(validate: false)).to eq true

        expect { no_user.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
        expect { no_task.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation

        no_tasklist_gid.tasklist_gid = nil
        expect { no_tasklist_gid.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      end
    end

    context 'against the model' do
      it 'in order to save' do
        expect(@task_user.save!).to eq true

        expect { no_user.save! }.to raise_error ActiveRecord::RecordInvalid
        expect { no_task.save! }.to raise_error ActiveRecord::RecordInvalid
      end

      it 'tasklist_gid is protected from being nil' do
        no_tasklist_gid.tasklist_gid = nil
        expect { no_tasklist_gid.save! }.not_to raise_error
      end
    end
  end

  describe 'requires uniqueness' do
    it 'on task and user' do
      @task_user.save

      duplicate = FactoryBot.build(:task_user, task: @task, user: @user, tasklist_gid: 'FAKEmdQ5NTUwMTk3NjU1MjE3MTU6MDo1001')
      expect { duplicate.save!(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
      expect { duplicate.save! }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'on google_id' do
      @task_user.save
      @task.update(title: 'validate')

      duplicate = FactoryBot.build(:task_user, task: @task, google_id: @task_user.google_id, tasklist_gid: 'FAKEmdQ5NTUwMTk3NjU1MjE3MTU6MDo1001')
      expect { duplicate.save!(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
      expect { duplicate.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe 'requires booleans to be in a state:' do
    let(:bad_deleted) { build :task_user, deleted: nil, tasklist_gid: 'FAKEmdQ5NTUwMTk3NjU1MjE3MTU6MDo1001' }

    it 'deleted' do
      expect { bad_deleted.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { bad_deleted.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe '#assign_from_api_fields' do
    it 'returns false if task_json is null' do
      task_user = TaskUser.new
      expect(task_user.assign_from_api_fields(nil)).to eq false
    end

    it 'uses a json hash to assign record values' do
      task_user = TaskUser.new
      task_json = JSON.parse(file_fixture('task_json_spec.json').read)

      expect(task_user.google_id).to eq nil
      expect(task_user.position).to eq nil
      expect(task_user.parent_id).to eq nil
      expect(task_user.deleted).to eq false
      expect(task_user.completed_at).to eq nil
      expect(task_user.updated_at).to eq nil

      task_user.assign_from_api_fields(task_json)

      expect(task_user.google_id).not_to eq nil
      expect(task_user.position).not_to eq nil
      expect(task_user.parent_id).not_to eq nil
      expect(task_user.completed_at).not_to eq nil
      expect(task_user.updated_at).not_to eq nil
    end
  end

  describe 'api interactions' do
    before :each do
      non_oauth_user = FactoryBot.create(:user)
      local_task = FactoryBot.create(:task, creator: non_oauth_user, owner: non_oauth_user)
      @local_task_user = FactoryBot.build(:task_user, task: local_task, user: non_oauth_user)
      @unsaved_task_user = FactoryBot.build(:task_user)
      WebMock.reset_executed_requests!
    end

    describe '#api_get' do
      it 'returns false for non-oauth users' do
        expect(@local_task_user.api_get).to eq false
      end

      it 'returns false if there\'s no google_id' do
        @task_user.google_id = nil
        expect(@task_user.api_get).to eq false
      end

      it 'returns false if there\'s no tasklist_gid' do
        @task_user.tasklist_gid = nil
        expect(@task_user.api_get).to eq false
      end

      it 'makes an API call' do
        @task_user.api_get
        expect(WebMock).to have_requested(:get, Constant::Regex::TASK)
      end

      it 'returns the API response' do
        response = @task_user.api_get
        expect(response['kind']).to eq 'tasks#task'
      end
    end

    describe '#api_insert' do
      it 'only fires during the after_create callback' do
        expect(@unsaved_task_user).to receive(:api_insert)
        @unsaved_task_user.save!

        expect(@unsaved_task_user).not_to receive(:api_insert)
        @unsaved_task_user.save!
      end

      it 'returns false for non-oauth users' do
        expect(@local_task_user.api_insert).to eq false
      end

      it 'returns false if there\'s no tasklist_gid' do
        @task_user.tasklist_gid = nil
        expect(@task_user.api_insert).to eq false
      end

      it 'makes an API call' do
        @task_user.api_insert
        expect(WebMock).to have_requested(:post, Constant::Regex::TASK)
      end

      it 'returns the API response' do
        response = @task_user.api_insert
        expect(response['kind']).to eq 'tasks#task'
      end
    end

    describe '#api_update' do
      it 'returns false for non-oauth users' do
        expect(@local_task_user.api_update).to eq false
      end

      it 'returns false if there\'s no google_id' do
        @task_user.google_id = nil
        expect(@task_user.api_update).to eq false
      end

      it 'returns false if there\'s no tasklist_gid' do
        @task_user.tasklist_gid = nil
        expect(@task_user.api_update).to eq false
      end

      it 'makes an API call' do
        @task_user.api_update
        expect(WebMock).to have_requested(:patch, Constant::Regex::TASK)
      end

      it 'returns the API response' do
        response = @task_user.api_update
        expect(response['kind']).to eq 'tasks#task'
      end
    end

    describe '#api_delete' do
      it 'only fires during the after_destroy callback' do
        expect(@unsaved_task_user).not_to receive(:api_delete)
        @unsaved_task_user.save!

        expect(@task_user).to receive(:api_delete)
        @task_user.destroy!
      end

      it 'returns false for non-oauth users' do
        expect(@local_task_user.api_delete).to eq false
      end

      it 'returns false if there\'s no google_id' do
        @task_user.google_id = nil
        expect(@task_user.api_delete).to eq false
      end

      it 'returns false if there\'s no tasklist_gid' do
        @task_user.tasklist_gid = nil
        expect(@task_user.api_delete).to eq false
      end

      it 'makes an API call' do
        @task_user.api_delete
        expect(WebMock).to have_requested(:delete, Constant::Regex::TASK)
      end
    end

    describe '#api_move' do
      it 'only fires if saved_changes_to_placement? is true' do
        @unsaved_task_user.save!
        expect(@unsaved_task_user).not_to receive(:api_move)
        @unsaved_task_user.update(position: 'positionID')

        expect(@task_user).to receive(:api_move)
        @task_user.update(parent_id: '100101001010011010')
      end

      it 'returns false for non-oauth users' do
        expect(@local_task_user.api_move).to eq false
      end

      it 'returns false unless api_fields_are_present?' do
        @task_user.google_id = nil
        expect(@task_user.api_move).to eq false
      end

      it 'makes an API call' do
        @task_user.api_move
        expect(WebMock).to have_requested(:post, Constant::Regex::TASK)
      end

      it 'returns the API response' do
        response = @task_user.api_move
        expect(response['kind']).to eq 'tasks#task'
      end
    end
  end

  describe '#saved_changes_to_placement?' do
    before :each do
      @task_user.update_column(:position, '00000000002147483647')
    end

    it 'requires at_least_one_placement_is_present?' do
      @task_user.update_column(:parent_id, nil)
      expect(@task_user.send(:saved_changes_to_placement?)).to eq false

      @task_user.update(parent_id: '00000000002147483647')
      expect(@task_user.send(:saved_changes_to_placement?)).to eq true
    end
    it 'returns false if no placements have changed' do
      @task_user.update(updated_at: Time.now)
      expect(@task_user.send(:saved_changes_to_placement?)).to eq false
    end

    it 'returns true if parent_id changed' do
      @task_user.update(parent_id: '100010100101001')
      expect(@task_user.send(:saved_changes_to_placement?)).to eq true
    end

    it 'returns true if previous_id changed' do
      @task_user.update(previous_id: '100010100101001')
      expect(@task_user.send(:saved_changes_to_placement?)).to eq true
    end
  end

  describe '#at_least_one_placement_is_present?' do
    let(:task_user_none)     { build :task_user }
    let(:task_user_parent)   { build :task_user, parent_id: 'parent' }
    let(:task_user_previous) { build :task_user, previous_id: 'previous' }

    it 'returns false if none are present' do
      expect(task_user_none.send(:at_least_one_placement_is_present?)).to eq false
    end

    it 'returns true if parent_id is present' do
      expect(task_user_parent.send(:at_least_one_placement_is_present?)).to eq true
    end

    it 'returns true if previous_id is present' do
      expect(task_user_previous.send(:at_least_one_placement_is_present?)).to eq true
    end
  end

  describe '#api_fields_are_present?' do
    let(:api_ready) { build :task_user, google_id: 'googleID', tasklist_gid: 'taslistGID' }
    let(:local_user) { create :user }
    let(:bare_task_user) { build :task_user, user: local_user }
    let(:oauth_task_user) { build :task_user }

    it 'returns true if all three are present' do
      expect(api_ready.send(:api_fields_are_present?)).to eq true
    end

    it 'returns false if only user.oauth_id is present' do
      expect(oauth_task_user.send(:api_fields_are_present?)).to eq false
    end

    it 'returns false if only google_id is present' do
      bare_task_user.google_id = 'something'
      expect(bare_task_user.send(:api_fields_are_present?)).to eq false
    end

    it 'returns false if only tasklist_gid is present' do
      bare_task_user.tasklist_gid = 'something'
      expect(bare_task_user.send(:api_fields_are_present?)).to eq false
    end
  end

  describe '#move_uri_builder' do
    context 'when no placements are present' do
      let(:placementless) { build :task_user, google_id: 'googleID', tasklist_gid: 'taslistGID' }

      it 'builds a URI' do
        expect(placementless.send(:move_uri_builder)).to eq 'https://www.googleapis.com/tasks/v1/lists/taslistGID/tasks/googleID/move?'
      end
    end

    context 'when parent_id is present' do
      let(:parentful) { build :task_user, google_id: 'googleID', tasklist_gid: 'taslistGID', parent_id: 'parentID' }

      it 'builds a URI' do
        expect(parentful.send(:move_uri_builder)).to eq 'https://www.googleapis.com/tasks/v1/lists/taslistGID/tasks/googleID/move?parent=parentID'
      end
    end

    context 'when previous_id is present' do
      let(:previousful) { build :task_user, google_id: 'googleID', tasklist_gid: 'taslistGID', previous_id: 'previousID' }

      it 'builds a URI' do
        expect(previousful.send(:move_uri_builder)).to eq 'https://www.googleapis.com/tasks/v1/lists/taslistGID/tasks/googleID/move?previous=previousID'
      end
    end

    context 'when both placements are present' do
      let(:placementful) { build :task_user, google_id: 'googleID', tasklist_gid: 'taslistGID', parent_id: 'parentID', previous_id: 'previousID' }

      it 'builds a URI' do
        expect(placementful.send(:move_uri_builder)).to eq 'https://www.googleapis.com/tasks/v1/lists/taslistGID/tasks/googleID/move?parent=parentID&previous=previousID'
      end
    end
  end

  describe '#set_position_as_integer' do
    let(:no_position) { create :task_user, task: @task }
    let(:has_position) { create :task_user, task: @task }

    it 'only fires if position is present' do
      no_position.update(position: nil)
      expect(no_position).not_to receive(:set_position_as_integer)
      no_position.save!

      expect(has_position).to receive(:set_position_as_integer)
      has_position.save!
    end

    it 'sets position_int field based upon position' do
      no_position.update(position: nil)
      expect(no_position.reload.position).to eq nil
      expect(no_position.position_int).to eq 0

      has_position.save!
      expect(has_position.reload.position).to eq '00000000001261646641'
      expect(has_position.position_int).to eq 1_261_646_641
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
      expect(fresh.tasklist_gid).to eq nil
      fresh.save
      fresh.reload
      tasklist_google_id = fresh.task.property.tasklists.where(user: fresh.user).first.google_id
      expect(fresh.tasklist_gid).to eq tasklist_google_id
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

  describe 'relocate' do
    it 'only fires on after_update callback when tasklist_gid changed' do
      @unsaved_task_user = FactoryBot.build(:task_user)
      expect(@unsaved_task_user).not_to receive(:relocate)
      @unsaved_task_user.save!

      expect(@task_user).to receive(:relocate)
      @task_user.update(tasklist_gid: '001001001')
    end

    it 'returns false if tasklist_gid didn\'t change' do
      @task_user.update(tasklist_gid: @task_user.tasklist_gid)
      expect(@task_user.send(:relocate)).to eq false
    end

    it 'makes a duplicate in memory and calls #api_delete' do
      expect_any_instance_of(TaskUser).to receive(:api_delete)
      @task_user.update(tasklist_gid: '001001001')
    end

    it 'calls #api_insert with the new tasklist_gid' do
      expect(@task_user).to receive(:api_insert)
      @task_user.update(tasklist_gid: '001001001')
    end
  end

  describe '#api_headers' do
    it 'returns a hash that includes the user\'s oauth_token' do
      response = @task_user.send(:api_headers)
      expect(response.as_json['Authorization']).to eq 'OAuth ' + @task_user.user.oauth_token
    end
  end

  describe '#api_body' do
    it 'returns a hash that describes the task' do
      response = @task_user.send(:api_body)
      expect(response[:title]).to eq @task_user.task.title
    end
  end
end
