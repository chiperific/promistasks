require 'rails_helper'

RSpec.describe SyncUserWithApiJob, type: :job do

  describe '#perform' do
    before :each do
      @user = double(:user)
      @tlc = TasklistsClient.new(@user)
      @tasklist = double(:tasklist)
      @task_user = double(:task_user)
      @tc = TasksClient.new(@tasklist)

      @list_tasklists_json = JSON.parse(file_fixture('list_tasklists_json_spec.json').read)
      @tasklist_json = FactoryBot.create(:tasklist_json)
      @default_tasklist_json = FactoryBot.create(:default_tasklist_json)
      @list_tasks_json = JSON.parse(file_fixture('list_tasks_json_spec.json').read)
      @task_json = FactoryBot.create(:task_json)

      allow(@tlc).to receive(:fetch).and_return(@list_tasklists_json)
      allow(@tlc).to receive(:count).and_return(3)
      allow(@tlc).to receive(:not_in_api).and_return([1, 2, 3, 4, 5]) # conditional, line 121
      allow(@tlc).to receive(:sync_default).and_return(@tasklist)
      allow(@tlc).to receive(:sync).and_return(@tasklist) # could be multiple
      allow(@tlc).to receive(:push)

      allow(TasksClient).to receive(:fetch_with_tasklist_gid_and_user).and_return(@list_tasks_json)
      allow(TasksClient).to receive(:not_in_api_with_tasklist_gid_and_user).and_return(@task_user) # could be multiple
      allow(TasksClient).to receive(:new).and_return(@tc)

      allow(@tc).to receive(:count).and_return(8) # conditional, line 61
      allow(@tc).to receive(:sync)
      allow(@tc).to receive(:not_in_api).and_return([1, 2, 3, 4, 5]) # conditional, line 101
      allow(@tc).to receive(:push)
    end

    context 'while setting the job\'s max value' do
      pending 'calls tlc.fetch'

      pending 'calls tlc.count'

      pending 'calls count on tlc.not_in_api'

      pending 'calls TasksClient.fetch_with_tasklist_gid_and_user multiple times'

      pending 'calls TasksClient.not_in_api_with_tasklist_gid_and_user multiple times'
    end

    context 'while handling the default tasklist' do
    end

    context 'while handling tasks for the the default tasklist' do
    end

    context 'while handling non-default tasklists' do
    end

    context 'while handling tasks for the non-default tasklists' do
    end

    context 'while handling missing tasklists' do
    end

    context 'while handling tasks for the missing tasklists' do
    end
  end
end
