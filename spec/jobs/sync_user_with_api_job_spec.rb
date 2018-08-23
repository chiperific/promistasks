# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SyncUserWithApiJob, type: :job do
  before :each do
    @list_tasklists_json = JSON.parse(file_fixture('list_tasklists_json_spec.json').read)
    @tasklist_json = FactoryBot.create(:tasklist_json)
    @default_tasklist_json = FactoryBot.create(:default_tasklist_json)
    @list_tasks_json = JSON.parse(file_fixture('list_tasks_json_spec.json').read)
    @task_json = FactoryBot.create(:task_json)

    @job = double(:delayed_job, update_columns: '', progress_current: 0, progress_max: 1000, message: '')
    @user = double(:user, id: 1)
    @tlc = double(:tasklists_client)

    @tasklist = double(:tasklist, user: @user)
    @tasklist_collection = [@tasklist, @tasklist, @tasklist]
    @task_user = double(:task_user)

    allow(User).to receive(:find).and_return(@user)
    allow(TasklistsClient).to receive(:new).and_return(@tlc)
    @sync_job = SyncUserWithApiJob.new(@user.id)
    @sync_job.before(@job)

    @tc = double(:tasks_client)
    allow(TasksClient).to receive(:new).and_return(@tc)

    allow(@tlc).to receive(:fetch).and_return(@list_tasklists_json)
    allow(@tlc).to receive(:count).and_return(3)
    allow(@tlc).to receive(:sync).and_return(@tasklist_collection)
    allow(@tlc).to receive(:push)
    allow(@tlc).to receive(:sync_default).and_return(@tasklist)
  end

  describe '#oauth_creds_exist' do
    it 'returns false if user has no oauth_id' do
      allow(@user).to receive(:oauth_id).and_return(nil)
      allow(@user).to receive(:oauth_token).and_return('1')
      allow(@user).to receive(:oauth_refresh_token).and_return('1')

      expect(@user.oauth_id.present?).to eq false
      expect(@sync_job.oauth_creds_exist).to eq false
    end

    it 'returns false if user has no oauth_token' do
      allow(@user).to receive(:oauth_id).and_return('1')
      allow(@user).to receive(:oauth_token).and_return(nil)
      allow(@user).to receive(:oauth_refresh_token).and_return('1')

      expect(@user.oauth_token.present?).to eq false
      expect(@sync_job.oauth_creds_exist).to eq false
    end

    it 'returns false if user has no oauth_refresh_token' do
      allow(@user).to receive(:oauth_id).and_return('1')
      allow(@user).to receive(:oauth_token).and_return('1')
      allow(@user).to receive(:oauth_refresh_token).and_return(nil)

      expect(@user.oauth_refresh_token.present?).to eq false
      expect(@sync_job.oauth_creds_exist).to eq false
    end

    it 'returns true if all three oauth fields are present' do
      allow(@user).to receive(:oauth_id).and_return('1')
      allow(@user).to receive(:oauth_token).and_return('1')
      allow(@user).to receive(:oauth_refresh_token).and_return('1')

      expect(@sync_job.oauth_creds_exist).to eq true
    end
  end

  describe '#perform' do
    before :each do
      allow(@sync_job).to receive(:determine_progress_max)
      allow(@sync_job).to receive(:process_tasklists).with(no_args).and_return(@tasklist_collection)
      allow(@sync_job).to receive(:process_tasklists).with(default: true).and_return(@tasklist)
      allow(@sync_job).to receive(:process_tasks)
      allow(@sync_job).to receive(:push_tasklists)
      allow(@sync_job).to receive(:push_from_app)
      allow(@tlc).to receive(:not_in_api).and_return([1, 2, 3, 4, 5])
      allow(@user).to receive(:oauth_id).and_return('1')
      allow(@user).to receive(:oauth_token).and_return('1')
      allow(@user).to receive(:oauth_refresh_token).and_return('1')
    end

    it 'calls #determine_progress_max' do
      expect(@sync_job).to receive(:determine_progress_max).once
      @sync_job.perform
    end

    it 'calls #process_tasklists with default' do
      expect(@sync_job).to receive(:process_tasklists).with(default: true).once
      @sync_job.perform
    end

    it 'calls #process_tasks with default' do
      expect(@sync_job).to receive(:process_tasks).with(@tasklist, default: true).once
      @sync_job.perform
    end

    it 'calls #process_tasklists without default' do
      expect(@sync_job).to receive(:process_tasklists).with(no_args).once
      @sync_job.perform
    end

    it 'calls #process_tasks without default multiple times' do
      expect(@sync_job).to receive(:process_tasks).with(@tasklist).exactly(3).times
      @sync_job.perform
    end

    it 'calls #find_tasklists' do
      expect(@sync_job).to receive(:find_tasklists).once
      @sync_job.perform
    end

    context 'when #find_tasklists returns results' do
      before :each do
        allow(@sync_job).to receive(:find_tasklists).and_return(@tasklist_collection)
      end

      it 'calls #push_tasklists' do
        expect(@sync_job).to receive(:push_tasklists)
        @sync_job.perform
      end

      it 'calls #push_from_app multiple times' do
        expect(@sync_job).to receive(:push_from_app).exactly(3).times
        @sync_job.perform
      end
    end

    context 'when #find_tasklists returns no results' do
      before :each do
        allow(@sync_job).to receive(:find_tasklists).and_return([])
      end

      it 'does not call #push_tasklists' do
        expect(@sync_job).not_to receive(:push_tasklists)
        @sync_job.perform
      end
    end

    it 'calls #wrap_up' do
      expect(@sync_job).to receive(:wrap_up)
      @sync_job.perform
    end
  end

  describe '#determine_progress_max' do
    before :each do
      allow(@tlc).to receive(:not_in_api).and_return([1, 2, 3, 4, 5])
      allow(TasksClient).to receive(:fetch_with_tasklist_gid_and_user).and_return(@list_tasks_json)
      allow(TasksClient).to receive(:not_in_api_with_tasklist_gid_and_user).and_return(@task_collection)
    end

    it 'calls tlc.fetch' do
      expect(@tlc).to receive(:fetch)
      @sync_job.determine_progress_max
    end

    it 'calls tlc.count' do
      expect(@tlc).to receive(:count)
      @sync_job.determine_progress_max
    end

    it 'calls tlc.not_in_api' do
      expect(@tlc).to receive(:not_in_api)
      @sync_job.determine_progress_max
    end

    it 'calls TasksClient.fetch_with_tasklist_gid_and_user multiple times' do
      expect(TasksClient).to receive(:fetch_with_tasklist_gid_and_user).exactly(3).times
      @sync_job.determine_progress_max
    end

    it 'calls TasksClient.not_in_api_with_tasklist_gid_and_user multiple times' do
      expect(TasksClient).to receive(:not_in_api_with_tasklist_gid_and_user).exactly(3).times
      @sync_job.determine_progress_max
    end
  end

  describe '#process_tasklists' do
    context 'when default' do
      it 'calls tlc.sync_default' do
        expect(@tlc).to receive(:sync_default)
        @sync_job.process_tasklists(default: true)
      end
    end

    context 'when not default' do
      it 'calls tlc.sync' do
        expect(@tlc).to receive(:sync)
        @sync_job.process_tasklists
      end

      it 'calls tlc.count' do
        expect(@tlc).to receive(:count)
        @sync_job.process_tasklists
      end
    end
  end

  describe '#find_tasklists' do
    it 'calls tlc.not_in_api' do
      allow(@tc).to receive(:not_in_api).and_return([1, 2, 3, 4, 5])

      expect(@tlc).to receive(:not_in_api)
      @sync_job.find_tasklists
    end
  end

  describe '#push_tasklists' do
    before :each do
      allow(@sync_job).to receive(:find_tasklists).and_return([1, 2, 3, 4, 5])
    end

    it 'calls tlc.push' do
      expect(@tlc).to receive(:push)
      @sync_job.push_tasklists
    end

    it 'calls #find_tasklists' do
      expect(@sync_job).to receive(:find_tasklists)
      @sync_job.push_tasklists
    end
  end

  describe '#process_tasks' do
    before :each do
      allow(@sync_job).to receive(:fetch_from_api)
      allow(@sync_job).to receive(:push_from_app)
    end

    it 'calls #fetch_from_api' do
      expect(@sync_job).to receive(:fetch_from_api).with(@tc, false)
      @sync_job.process_tasks(@tasklist)
    end

    it 'calls #push_from_app' do
      expect(@sync_job).to receive(:push_from_app).with(@tc)
      @sync_job.process_tasks(@tasklist)
    end
  end

  describe '#fetch_from_api' do
    it 'calls tasks_client.count' do
      allow(@tc).to receive(:count).and_return(0)

      expect(@tc).to receive(:count)
      @sync_job.fetch_from_api(@tc, false)
    end

    context 'when tasks_client.count is positive' do
      it 'calls tasks_client.sync' do
        allow(@tc).to receive(:count).and_return(8)

        expect(@tc).to receive(:sync)
        @sync_job.fetch_from_api(@tc, false)
      end
    end

    context 'when tasks_client.count is not positive' do
      before :each do
        allow(@tc).to receive(:count).and_return(0)
      end

      it 'does not call tasks_client.sync' do
        expect(@tc).not_to receive(:sync)
        @sync_job.fetch_from_api(@tc, false)
      end
    end
  end

  describe '#push_from_app' do
    it 'calls tasks_client.not_in_api' do
      expect(@tc).to receive(:not_in_api)
      @sync_job.push_from_app(@tc)
    end

    context 'when not_in_api returns records' do
      it 'calls tasks_client.push' do
        allow(@tc).to receive(:not_in_api).and_return([1, 2, 3, 4, 5])

        expect(@tc).to receive(:push)
        @sync_job.push_from_app(@tc)
      end
    end

    context 'when not_in_api returns nothing' do
      it 'doesn\'t call tasks_client.push' do
        allow(@tc).to receive(:not_in_api).and_return([])

        expect(@tc).not_to receive(:push)
        @sync_job.push_from_app(@tc)
      end
    end
  end
end
