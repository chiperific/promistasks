# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TasksClient, type: :service do
  before :each do
    @user = FactoryBot.create(:oauth_user)
  end

  describe '#sync' do
    before :each do
      @local_user = FactoryBot.create(:user)
      @property = FactoryBot.create(:property, creator: @user, is_private: true)
      @tasklist = @property.reload.tasklists.first
      @missing_task = FactoryBot.create(:task, property: @property, creator: @user, owner: @user)
    end

    it 'returns false if the user isn\'t oauth' do
      expect(TasksClient.sync(@local_user, @tasklist)).to eq false
    end

    it 'refreshes the user token' do
      expect(@user).to receive(:refresh_token!)
      TasksClient.sync(@user, @tasklist)
    end

    it 'calls user.list_api_tasklists' do
      expect(@tasklist).to receive(:list_api_tasks)
      TasksClient.sync(@user, @tasklist)
    end

    it 'calls handle_tasklist' do
      expect(TasksClient).to receive(:handle_task).exactly(8).times
      TasksClient.sync(@user, @tasklist)
    end

    it 'calls task_user.api_update for missing tasks' do
      expect_any_instance_of(TaskUser).to receive(:api_insert)
      TasksClient.sync(@user, @tasklist)
    end

    it 'returns an array of task IDs that were synced' do
      ary = TasksClient.sync(@user, @tasklist)
      expect(ary.length).to eq 8
    end
  end

  describe '#handle_tasks' do
    before :each do
      @task_json = {
                      kind: 'tasks#task',
                      id: 'FAKEMDQ5NTUwMTk3NjU1MjE3MTU6MDA1NTU3Nzg4MzU0MDI2MDoyMTA5ODkyNTk4MDE0ODcz',
                      etag: '\"-7OFI3jKFsqNjDtcscX9ImH8hVU/NTE4OTQwOTE\"',
                      title: 'Gut the bathroom',
                      updated: '2018-06-10T15:15:27.000Z',
                      selfLink: 'https://www.googleapis.com/tasks/v1/lists/FAKEMDQ5NTUwMTk3NjU1MjE3MTU6MDA1NTU3Nzg4MzU0MDI2MDow/tasks/FAKEMDQ5NTUwMTk3NjU1MjE3MTU6MDA1NTU3Nzg4MzU0MDI2MDoyMTA5ODkyNTk4MDE0ODcz',
                      position: '00000000002147483647',
                      status: 'needsAction'
                    }.as_json
      @this_user = FactoryBot.create(:oauth_user, name: 'this')
      @existing_property = FactoryBot.create(:property, name: 'this', creator: @this_user, is_private: true)
      @existing_property.reload
                        .tasklists
                        .first
                        .update(google_id: 'FAKEMDQ5NTUwMTk3NjU1MjE3MTU6MDA1NTU3Nzg4MzU0MDI2MDow')
      @tasklist = @existing_property.tasklists.where(user: @this_user).first
      @task = FactoryBot.create(:task,
                                creator: @this_user,
                                owner: @this_user,
                                property: @existing_property,
                                title: 'Gut the bathroom',
                                created_from_api: true)
      @task_user = FactoryBot.create(:task_user,
                                     user: @this_user,
                                     task: @task,
                                     tasklist_gid: 'FAKEMDQ5NTUwMTk3NjU1MjE3MTU6MDA1NTU3Nzg4MzU0MDI2MDow',
                                     google_id: 'FAKEMDQ5NTUwMTk3NjU1MjE3MTU6MDA1NTU3Nzg4MzU0MDI2MDoyMTA5ODkyNTk4MDE0ODcz',
                                     position: '00000000002147483647')
      allow(TasksClient).to receive(:create_task) { @task }
      allow(TasksClient).to receive(:update_task_user) { @task_user }
    end

    context 'when task doesn\'t exist' do
      pending 'creates a task and updates the task_user' do
        task_count = Task.count
        task_user_count = TaskUser.count
        TasksClient.handle_task(@task_json)
        expect(Task.count).to eq task_count + 1
        expect(TaskUser.count).to eq task_user_count + 1
      end

      pending 'doesn\'t trigger task.create_task_users'
        # expect_any_instance_of(Task).not_to receive(:create_task_users)
        # TasksClient.handle_task(@task_json)
    end

    context 'when task exists' do
      before :each do
        @existing_task = FactoryBot.create(:task, creator: @this_user, owner: @this_user, property: @existing_property)
        @existing_task.reload
                      .task_users
                      .first
                      .update(google_id: 'FAKEMDQ5NTUwMTk3NjU1MjE3MTU6MDA1NTU3Nzg4MzU0MDI2MDoyMTA5ODkyNTk4MDE0ODcz')
      end

      context 'and the API record is newer' do
        before :each do
          task_user = @existing_task.task_users.first
          task_user.update_column(:updated_at, '2018-06-08T23:22:03.000Z')
        end

        pending 'updates the task and task_user' do
          expect(TasksClient).to receive(:update_task)
          expect(TasksClient).to receive(:update_task_user)
          TasksClient.handle_task(@task_json)
        end

        pending 'doesn\'t trigger task.create_task_users'
          # expect_any_instance_of(Task).not_to receive(:create_task_users)
          # TasksClient.handle_task(@task_json)
      end

      context 'and the API record is older' do
        pending 'triggers task_user.api_update'
      end
    end
  end
end
