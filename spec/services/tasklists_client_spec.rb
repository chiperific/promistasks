# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TasklistsClient, type: :service do
  before :each do
    stub_request(:any, Constant::Regex::TASK).to_return(
      headers: { 'Content-Type'=> 'application/json' },
      status: 200,
      body: FactoryBot.create(:task_json).marshal_dump.to_json
    )
    stub_request(:any, Constant::Regex::TASKLIST).to_return(
      headers: { 'Content-Type'=> 'application/json' },
      status: 200,
      body: FactoryBot.create(:tasklist_json).marshal_dump.to_json
    )
    stub_request(:get, 'https://www.googleapis.com/tasks/v1/users/@me/lists').to_return(
      headers: { 'Content-Type'=> 'application/json' },
      status: 200,
      body: file_fixture('list_tasklists_json_spec.json').read
    )
    @local_user = FactoryBot.create(:user)
    @user = FactoryBot.create(:oauth_user)
    # @local_tasklist = FactoryBot.create(:tasklist, user: @local_user)
    # @tasklist = FactoryBot.create(:tasklist, user: @user)
  end

  describe '#new' do
    it 'refreshes the user token' do
      expect(@user).to receive(:refresh_token!)
      TasklistsClient.new(@user)
    end
  end

  fdescribe '#start' do
    it 'calls user.list_api_tasklists' do
      expect(@user).to receive(:list_api_tasklists)
      TasklistsClient.sync(@user)
    end

    it 'returns false if user.list_api_tasklists fails' do
      expect(TasklistsClient.sync(@local_user)).to eq false
    end
    pending 'fetches all tasklists for a user'
    pending 'creates new tasklists'
    pending 'creates new properties'
  end
end
