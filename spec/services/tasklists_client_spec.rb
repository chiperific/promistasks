# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TasklistsClient, type: :service do
  before :each do
    @user = FactoryBot.create(:oauth_user)
    @local_user = FactoryBot.create(:user)
    @missing_property = FactoryBot.create(:property, creator: @user, is_private: true)
  end

  describe '#sync' do
    it 'returns false if the user isn\'t oauth' do
      expect(TasklistsClient.sync(@local_user)).to eq false
    end

    it 'refreshes the user token' do
      expect(@user).to receive(:refresh_token!)
      TasklistsClient.sync(@user)
    end

    it 'fetches the default tasklist' do
      # expect(@user).to receive(:fetch_default_tasklist) # ARGHHHH!
      TasklistsClient.sync(@user)
      expect(WebMock).to have_requested(:get, 'https://www.googleapis.com/tasks/v1/users/@me/lists/@default').once
    end

    it 'calls user.list_api_tasklists' do
      expect(@user).to receive(:list_api_tasklists)
      TasklistsClient.sync(@user)
    end

    it 'calls handle_tasklist' do
      expect(TasklistsClient).to receive(:handle_tasklist).exactly(4).times
      TasklistsClient.sync(@user)
    end

    it 'calls tasklist.api_update for missing properties' do
      expect_any_instance_of(Tasklist).to receive(:api_insert)
      TasklistsClient.sync(@user)
    end

    it 'returns an array of property IDs that were synced from the API' do
      ary = TasklistsClient.sync(@user)
      expect(ary.uniq.length).to eq 3
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
          expect { TasklistsClient.handle_tasklist(@tasklist_json, true) }.to change { Property.where(is_default: true).count }.by 1
        end

        it 'creates a tasklists for the property' do
          expect { TasklistsClient.handle_tasklist(@tasklist_json, true) }.to change { Tasklist.count }.by 1
        end

        it 'doesn\'t call tasklist.api_insert' do
          expect_any_instance_of(Tasklist).not_to receive(:api_insert)
          TasklistsClient.handle_tasklist(@tasklist_json, true)
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

          it 'doesn\'t change the property\'s name' do
            expect { TasklistsClient.handle_tasklist(@tasklist_json, true) }.not_to change { @default_property.reload.name }
          end

          it 'updates the tasklist\'s updated_at field' do
            expect { TasklistsClient.handle_tasklist(@tasklist_json, true) }.to change { @default_property.reload.tasklists.first.updated_at }
          end
        end

        context 'when the API record is older' do
          it 'doesn\'t change the API version\'s name' do
            @default_property.update_column(:name, 'Not My Tasks')
            expect_any_instance_of(Tasklist).not_to receive(:api_update)
            TasklistsClient.handle_tasklist(@tasklist_json, true)
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
        it 'creates a property' do
          expect { TasklistsClient.handle_tasklist(@tasklist_json) }.to change { Property.where(is_default: false).count }.by 1
        end

        it 'creates a tasklists for the property' do
          expect { TasklistsClient.handle_tasklist(@tasklist_json) }.to change { Tasklist.count }.by 1
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
            expect { TasklistsClient.handle_tasklist(@tasklist_json) }.to change { @existing_property.reload.name }
          end

          it 'updates the tasklist' do
            expect { TasklistsClient.handle_tasklist(@tasklist_json) }.to change { @existing_property.reload.tasklists.first.updated_at }
          end
        end

        context 'when the API record is older' do
          it 'updates the API version' do
            expect_any_instance_of(Tasklist).to receive(:api_update).once
            TasklistsClient.handle_tasklist(@tasklist_json)
          end
        end
      end
    end
  end
end
