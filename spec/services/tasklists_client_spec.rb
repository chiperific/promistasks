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
    stub_request(:get, 'https://www.googleapis.com/tasks/v1/users/@me/lists/@default').to_return(
      headers: { 'Content-Type'=> 'application/json' },
      status: 200,
      body: FactoryBot.create(:default_tasklist_json).marshal_dump.to_json
    )
    @user = FactoryBot.create(:oauth_user)
    @local_user = FactoryBot.create(:user)
    @tlc = TasklistsClient.new(@user)
    @tlc_l = TasklistsClient.new(@local_user)
  end

  describe '#sync' do
    it 'returns false if the user isn\'t oauth' do
      expect(@tlc_l.sync).to eq false
    end

    it 'refreshes the user token' do
      expect_any_instance_of(User).to receive(:refresh_token!)
      @tlc.sync
    end

    it 'fetches the default tasklist' do
      # expect_any_instance_of(User).to receive(:fetch_default_tasklist) # huh?!?
      @tlc.sync
      expect(WebMock).to have_requested(:get, 'https://www.googleapis.com/tasks/v1/users/@me/lists/@default').once
    end

    it 'calls user.list_api_tasklists' do
      expect_any_instance_of(User).to receive(:list_api_tasklists)
      @tlc.sync
    end

    it 'calls handle_tasklist' do
      expect(@tlc).to receive(:handle_tasklist).exactly(4).times
      @tlc.sync
    end
  end

  describe '#handle_tasklist' do
    context 'when default' do
      context 'and tasklist doesn\'t exist' do
        before :each do
          @tasklist_json = {
                             kind: 'tasks#taskList',
                             id: 'FAKEMDQ5NTUwMTk3NjU1MjE3MTU6NDU5OTEwNjgyNjcyMjUzNjow',
                             title: '1001 Alexander St SE',
                             updated: '2018-06-10T15:23:17.000Z',
                             selfLink: 'https://www.googleapis.com/tasks/v1/users/@me/lists/FAKEMDQ5NTUwMTk3NjU1MjE3MTU6NDU5OTEwNjgyNjcyMjUzNjow'
                           }.as_json
        end

        it 'creates a default property' do
          expect { @tlc.handle_tasklist(@tasklist_json, true) }.to change { Property.where(is_default: true).count }.by 1
        end

        it 'creates a tasklists for the property' do
          expect { @tlc.handle_tasklist(@tasklist_json, true) }.to change { Tasklist.count }.by 1
        end

        it 'doesn\'t call tasklist.api_insert' do
          expect_any_instance_of(Tasklist).not_to receive(:api_insert)
          @tlc.handle_tasklist(@tasklist_json, true)
        end
      end

      context 'and tasklist exists' do
        before :each do
          @default_property = FactoryBot.create(:property, creator: @user, is_default: true)
          @default_property.reload
                           .tasklists
                           .first
                           .update(google_id: 'FAKEMDQ5NTUwMTk3NjU1MjE3MTU6MDow')
          @tasklist_json = {
                             kind: 'tasks#taskList',
                             id: 'FAKEMDQ5NTUwMTk3NjU1MjE3MTU6MDow',
                             title: 'My Tasks',
                             updated: '2018-06-10T23:22:03.000Z',
                             selfLink: 'https://www.googleapis.com/tasks/v1/users/@me/lists/FAKEMDQ5NTUwMTk3NjU1MjE3MTU6MDow'
                           }.as_json
        end

        context 'when the API record is newer' do
          before :each do
            tasklist = @default_property.tasklists.first
            tasklist.update_column(:updated_at, '2018-06-08T23:22:03.000Z')
          end

          it 'updates the property' do
            expect { @tlc.handle_tasklist(@tasklist_json, true) }.to change { @default_property.reload.name }
          end

          it 'updates the tasklist' do
            expect { @tlc.handle_tasklist(@tasklist_json, true) }.to change { @default_property.reload.tasklists.first.updated_at }
          end
        end

        context 'when the API record is older' do
          it 'updates the API version' do
            @default_property.update_column(:name, 'Not My Tasks')
            expect_any_instance_of(Tasklist).to receive(:api_update).once
            @tlc.handle_tasklist(@tasklist_json, true)
          end
        end
      end
    end

    context 'when not default' do
      before :each do
        @tasklist_json = {
                           kind: 'tasks#taskList',
                           id: 'FAKEMDQ5NTUwMTk3NjU1MjE3MTU6NDU5OTEwNjgyNjcyMjUzNjow',
                           title: '1001 Alexander St SE',
                           updated: '2018-06-10T15:23:17.000Z',
                           selfLink: 'https://www.googleapis.com/tasks/v1/users/@me/lists/FAKEMDQ5NTUwMTk3NjU1MjE3MTU6NDU5OTEwNjgyNjcyMjUzNjow'
                         }.as_json
      end

      context 'and tasklist doesn\'t exist' do
        it 'creates a default property' do
          expect { @tlc.handle_tasklist(@tasklist_json) }.to change { Property.where(is_default: false).count }.by 1
        end

        it 'creates a tasklists for the property' do
          expect { @tlc.handle_tasklist(@tasklist_json) }.to change { Tasklist.count }.by 1
        end
      end

      context 'and tasklist exists' do
        before :each do
          @existing_property = FactoryBot.create(:property, creator: @user)
          @existing_property.reload
                            .tasklists
                            .first
                            .update(google_id: 'FAKEMDQ5NTUwMTk3NjU1MjE3MTU6NDU5OTEwNjgyNjcyMjUzNjow')
        end
        context 'when the API record is newer' do
          before :each do
            tasklist = @existing_property.tasklists.first
            tasklist.update_column(:updated_at, '2018-06-08T23:22:03.000Z')
          end

          it 'updates the property' do
            expect { @tlc.handle_tasklist(@tasklist_json) }.to change { @existing_property.reload.name }
          end

          it 'updates the tasklist' do
            expect { @tlc.handle_tasklist(@tasklist_json) }.to change { @existing_property.reload.tasklists.first.updated_at }
          end
        end

        context 'when the API record is older' do
          it 'updates the API version' do
            expect_any_instance_of(Tasklist).to receive(:api_update).once
            @tlc.handle_tasklist(@tasklist_json)
          end
        end
      end
    end
  end
end
