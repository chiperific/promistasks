# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TasksClient, type: :service do
  before :each do
    @list_api_tasks = JSON.parse(file_fixture('list_tasks_json_spec.json').read)
    @user = double(:user, id: 1, refresh_token!: true)
    @property = double(:property, id: 1)
    @tasklist = double(:tasklist, user: @user, property: @property, list_api_tasks: @list_api_tasks, google_id: 'google_id')
    @error_response = { 'errors' => [
      { 'domain' => 'global', 'reason' => 'authError', 'message' => 'Invalid Credentials', 'locationType' => 'header', 'location' => 'Authorization' }
    ], 'code' => 401, 'message' => 'Invalid Credentials' }
    @tc = TasksClient.new(@tasklist)
    @task = stub_model(Task)
    @new_task = stub_model(Task).as_new_record
  end

  describe 'self.fetch_with_tasklist_gid_and_user' do
    it 'returns false if user.oauth_token is not present' do
      allow(@user).to receive(:oauth_token).and_return(nil)

      expect(TasksClient.fetch_with_tasklist_gid_and_user('google_id', @user)).to eq false
    end

    it 'calls user.refresh_token!' do
      allow(@user).to receive(:oauth_token).and_return('oauth_token')

      expect(@user).to receive(:refresh_token!).once
      TasksClient.fetch_with_tasklist_gid_and_user('google_id', @user)
    end

    it 'makes an API call' do
      allow(@user).to receive(:oauth_token).and_return('oauth_token')

      TasksClient.fetch_with_tasklist_gid_and_user('google_id', @user)

      expect(WebMock).to have_requested(:get, Constant::Regex::LIST_TASKS).once
    end

    it 'returns an API response' do
      allow(@user).to receive(:oauth_token).and_return('oauth_token')

      expect(TasksClient.fetch_with_tasklist_gid_and_user('google_id', @user)['kind']).to eq 'tasks#tasks'
    end
  end

  describe 'self.not_in_api_with_tasklist_gid_and_user' do
    it 'calls self.fetch_with_tasklist_gid_and_user' do
      allow(TasksClient).to receive(:fetch_with_tasklist_gid_and_user).and_return(@list_api_tasks)

      expect(TasksClient).to receive(:fetch_with_tasklist_gid_and_user).with('google_id', @user).once
      TasksClient.not_in_api_with_tasklist_gid_and_user('google_id', @user)
    end

    it 'calls TaskUser.where' do
      allow(TasksClient).to receive(:fetch_with_tasklist_gid_and_user).and_return(@list_api_tasks)
      allow(TaskUser).to receive_message_chain('where.where.where.not').and_return([1, 2])

      expect(TaskUser).to receive_message_chain(:where, :where, :where, :not) { [1, 2] }
      TasksClient.not_in_api_with_tasklist_gid_and_user('google_id', @user)
    end
  end

  describe '#connect' do
    it 'calls user.refresh_token!' do
      expect(@user).to receive(:refresh_token!).once
      @tc.connect
    end
  end

  describe '#count' do
    it 'calls #fetch' do
      allow(@tc).to receive(:fetch).and_return(@list_api_tasks)

      expect(@tc).to receive(:fetch).once
      @tc.count
    end

    it 'counts a json hash' do
      allow(@tc).to receive(:fetch).and_return(@list_api_tasks)

      expect(@tc.count).to eq 8
    end
  end

  describe '#create_task' do
    before :each do
      allow(Task).to receive(:create).and_return(@new_task)
      allow(@new_task).to receive(:save!).and_return(@task)
      allow(@new_task).to receive(:reload).and_return(@task)
    end

    it 'calls Task.create' do
      expect(Task).to receive(:create).once
      @tc.create_task(@task_json)
    end

    it 'calls task.save!' do
      expect(@new_task).to receive(:save!).once
      @tc.create_task(@task_json)
    end

    it 'calls task.reload' do
      expect(@new_task).to receive(:reload).once
      @tc.create_task(@task_json)
    end
  end

  describe '#fetch' do
    it 'calls #connect' do
      expect(@tc).to receive(:connect).once
      @tc.fetch
    end

    it 'calls tasklist.list_api_tasks' do
      expect(@tasklist).to receive(:list_api_tasks).once
      @tc.fetch
    end
  end

  describe '#handle_task' do
    before :each do
      @task_json = FactoryBot.create(:task_json)
      @new_task_user = stub_model(TaskUser).as_new_record
      @task_user = stub_model(TaskUser)
      allow(@tc).to receive(:create_task).and_return(@task)
      allow(@tc).to receive(:update_task).and_return(@task)
      allow(@tc).to receive(:update_task_user).and_return(@task_user)
    end

    it 'finds or initilizes a TaskUser' do
      allow(TaskUser).to receive_message_chain('where.first_or_initialize').and_return(@new_task_user)

      expect(TaskUser).to receive(:where).once
      @tc.handle_task(@task_json)
    end

    context 'when task_user is a new record' do
      it 'calls #create_task' do
        allow(TaskUser).to receive_message_chain('where.first_or_initialize').and_return(@new_task_user)

        expect(@tc).to receive(:create_task).once
        @tc.handle_task(@task_json)
      end

      it 'calls #update_task_user' do
        allow(TaskUser).to receive_message_chain('where.first_or_initialize').and_return(@new_task_user)

        expect(@tc).to receive(:update_task_user).once
        @tc.handle_task(@task_json)
      end
    end

    context 'when task_user exists' do
      before :each do
        allow(TaskUser).to receive_message_chain('where.first_or_initialize').and_return(@task_user)
      end

      context 'and task_user is older than the json' do
        before :each do
          allow(@task_user).to receive(:updated_at).and_return(Time.now - 2.days)
        end

        it 'calls #update_task' do
          expect(@tc).to receive(:update_task)
          @tc.handle_task(@task_json)
        end

        it 'calls #update_task_user' do
          expect(@tc).to receive(:update_task_user)
          @tc.handle_task(@task_json)
        end
      end

      context 'and task_user is newer than the json' do
        before :each do
          allow(@task_user).to receive(:updated_at).and_return(Time.now + 2.minutes)
        end

        it 'calls task_user.api_update' do
          expect(@task_user).to receive(:api_update).once
          @tc.handle_task(@task_json)
        end
      end
    end
  end

  describe '#not_in_api' do
    it 'calls #fetch' do
      allow(@tc).to receive(:fetch).and_return(@list_api_tasks)

      expect(@tc).to receive(:fetch).once
      @tc.not_in_api
    end

    it 'calls TaskUser.where' do
      allow(@tc).to receive(:fetch).and_return(@list_api_tasks)
      allow(TaskUser).to receive_message_chain('where.where.where.not').and_return([1, 2])

      expect(TaskUser).to receive_message_chain(:where, :where, :where, :not) { [1, 2] }
      @tc.not_in_api
    end
  end

  describe '#push' do
    it 'calls #not_in_api' do
      allow(@tc).to receive(:fetch).and_return(@list_api_tasks)

      expect(@tc).to receive(:not_in_api)
      @tc.push
    end

    it 'returns false if #not_in_api returns nothing' do
      allow(@tc).to receive(:not_in_api).and_return([])
      expect(@tc.push).to eq false
    end

    it 'calls task_user.api_insert' do
      taskuser1 = double(:task_user, api_insert: '')
      taskuser2 = double(:task_user, api_insert: '')
      tu_container = [taskuser1, taskuser2]
      allow(@tc).to receive(:not_in_api).and_return(tu_container)
      @tc.push

      expect(taskuser1).to have_received(:api_insert).once
      expect(taskuser2).to have_received(:api_insert).once
    end
  end

  describe '#sync' do
    it 'calls #fetch' do
      expect(@tc).to receive(:fetch).once
      @tc.sync
    end

    it 'returns nil if tasks_json is nil' do
      allow(@tc).to receive(:fetch).and_return(nil)
      expect(@tc.sync).to eq nil
    end

    it 'returns tasks_json if tasks_json contains errors' do
      allow(@tc).to receive(:fetch).and_return(@error_response)
      expect(@tc.sync).to eq @error_response
    end

    it 'calls #handle_task for each tasks_json item' do
      allow(@tc).to receive(:fetch).and_return(@list_api_tasks)

      expect(@tc).to receive(:handle_task).exactly(8).times
      @tc.sync
    end
  end

  describe '#update_task' do
    before :each do
      allow(@task).to receive(:save!).and_return(@task)
      allow(@task).to receive(:reload).and_return(@task)
    end

    it 'calls task.save!' do
      expect(@task).to receive(:save!).once
      @tc.update_task(@task, @task_json)
    end

    it 'calls task.reload' do
      expect(@task).to receive(:reload).once
      @tc.update_task(@task, @task_json)
    end
  end

  describe '#update_task_user' do
    before :each do
      @task_user = double(:task_user)
      allow(@task_user).to receive(:user_id=)
      allow(@task_user).to receive(:assign_from_api_fields).with(@task_json)
      allow(@task_user).to receive(:tasklist_gid=)
      allow(@task_user).to receive(:scope=)
      allow(@task_user).to receive(:save!).and_return(@task_user)
      allow(@task_user).to receive(:reload).and_return(@task_user)
    end

    it 'calls task_user.save!' do
      expect(@task_user).to receive(:save!).once
      @tc.update_task_user(@task_user, @task_json)
    end

    it 'calls task_user.reload' do
      expect(@task_user).to receive(:reload).once
      @tc.update_task_user(@task_user, @task_json)
    end
  end
end
