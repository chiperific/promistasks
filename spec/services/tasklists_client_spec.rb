# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TasklistsClient, type: :service do
  before :each do
    @user = FactoryBot.create(:oauth_user)
    @tc = TasklistsClient.new(@user)
    @good_response = JSON.parse(file_fixture('list_tasklists_json_spec.json').read)
    @default_response = FactoryBot.create(:default_tasklist_json)
    @error_response = { 'errors' => [
      { 'domain' => 'global', 'reason' => 'authError', 'message' => 'Invalid Credentials', 'locationType' => 'header', 'location' => 'Authorization' }
    ], 'code' => 401, 'message' => 'Invalid Credentials' }
    @property = stub_model(Property)
    @new_property = stub_model(Property).as_new_record
  end

  describe '#connect' do
    it 'calls user.refresh_token!' do
      expect(@user).to receive(:refresh_token!).once
      @tc.connect
    end
  end

  describe '#count' do
    it 'calls #fetch' do
      allow(@tc).to receive(:fetch).and_return(@good_response)

      expect(@tc).to receive(:fetch).once
      @tc.count
    end

    it 'counts a json hash' do
      allow(@tc).to receive(:fetch).and_return(@good_response)

      expect(@tc.count).to eq 3
    end
  end

  describe '#create_property' do
    context 'when the property exists' do
      it 'returns the existing property' do
        prop = FactoryBot.create(:property, name: 'title')

        expect(@tc.create_property('title', false)).to eq prop
      end
    end

    context 'when the property doesn\'t exist' do
      it 'creates the property' do
        expect { @tc.create_property('title', false) }.to change { Property.all.size }.by(1)
      end
    end

    it 'returns a property' do
      expect(@tc.create_property('title', false).class).to eq Property
    end
  end

  describe '#fetch' do
    it 'calls #connect' do
      expect(@tc).to receive(:connect).once
      @tc.fetch
    end

    it 'calls user.list_api_tasklists' do
      expect(@user).to receive(:list_api_tasklists)
      @tc.fetch
    end
  end

  describe '#fetch_default' do
    it 'calls #connect' do
      expect(@tc).to receive(:connect).once
      @tc.fetch_default
    end

    it 'calls user.fetch_default_tasklist' do
      expect(@user).to receive(:fetch_default_tasklist)
      @tc.fetch_default
    end
  end

  describe '#handle_tasklist' do
    before :each do
      @tasklist_json = FactoryBot.create(:tasklist_json)
      @new_tasklist = stub_model(Tasklist).as_new_record
      @tasklist = stub_model(Tasklist)
      allow(@tc).to receive(:create_property).and_return(@property)
    end

    it 'finds or initializes a Tasklist' do
      allow(Tasklist).to receive_message_chain('where.first_or_initialize').and_return(@new_tasklist)
      allow(Tasklist).to receive_message_chain('where.first').and_return(@tasklist)
      allow(@new_tasklist).to receive(:save!).and_return(true)
      allow(@new_tasklist).to receive(:reload).and_return(@new_tasklist)

      expect(Tasklist).to receive(:where).twice
      @tc.handle_tasklist(@tasklist_json)
    end

    context 'when tasklist is a new record' do
      before :each do
        allow(Tasklist).to receive_message_chain('where.first_or_initialize').and_return(@new_tasklist)
        allow(Tasklist).to receive_message_chain('where.first').and_return(@tasklist)
        allow(@new_tasklist).to receive(:save!).and_return(true)
        allow(@new_tasklist).to receive(:reload).and_return(@new_tasklist)
      end

      it 'calls #create_property' do
        expect(@tc).to receive(:create_property)
        @tc.handle_tasklist(@tasklist_json)
      end

      it 'calls tasklist.save!' do
        expect(@new_tasklist).to receive(:save)
        @tc.handle_tasklist(@tasklist_json)
      end
    end

    context 'when tasklist exists' do
      before :each do
        allow(Tasklist).to receive_message_chain('where.first_or_initialize').and_return(@tasklist)
        allow(Tasklist).to receive_message_chain('where.first').and_return(@tasklist)
        allow(@tasklist).to receive(:reload).and_return(@tasklist)
      end

      context 'and tasklist is older than the json' do
        before :each do
          allow(@tasklist).to receive(:updated_at).and_return(Time.now - 2.days)
        end

        it 'calls #update_property' do
          expect(@tc).to receive(:update_property)
          @tc.handle_tasklist(@tasklist_json)
        end

        it 'calls tasklist.update' do
          allow(@tc).to receive(:update_property).and_return(@property)
          expect(@tasklist).to receive(:update)
          @tc.handle_tasklist(@tasklist_json)
        end
      end

      context 'and tasklist is newer than the json' do
        before :each do
          allow(@tasklist).to receive(:updated_at).and_return(Time.now + 2.minutes)
        end

        context 'and the default flag is true' do
          it 'doesn\'t call tasklist.api_update' do
            expect(@tasklist).not_to receive(:api_update)
            @tc.handle_tasklist(@tasklist_json, true)
          end
        end

        context 'and the default flag is false' do
          it 'calls tasklist.api_update' do
            expect(@tasklist).to receive(:api_update)
            @tc.handle_tasklist(@tasklist_json)
          end
        end
      end
    end
  end

  describe '#not_in_api' do
    it 'calls #fetch' do
      allow(@tc).to receive(:fetch).and_return(@good_response)

      expect(@tc).to receive(:fetch).once
      @tc.not_in_api
    end

    it 'calls Tasklist.where' do
      allow(@tc).to receive(:fetch).and_return(@good_response)
      allow(Tasklist).to receive_message_chain('where.where.not').and_return([1, 2])

      expect(Tasklist).to receive_message_chain(:where, :where, :not) { [1, 2] }
      @tc.not_in_api
    end
  end

  describe '#push' do
    it 'calls #not_in_api' do
      allow(@tc).to receive(:fetch).and_return(@good_response)

      expect(@tc).to receive(:not_in_api)
      @tc.push
    end

    it 'returns false if #not_in_api returns nothing' do
      allow(@tc).to receive(:not_in_api).and_return([])
      expect(@tc.push).to eq false
    end

    it 'calls tasklist.api_insert' do
      tasklist1 = double(:tasklist, api_insert: '')
      tasklist2 = double(:tasklist, api_insert: '')
      tl_container = [tasklist1, tasklist2]
      allow(@tc).to receive(:not_in_api).and_return(tl_container)
      @tc.push

      expect(tasklist1).to have_received(:api_insert).once
      expect(tasklist2).to have_received(:api_insert).once
    end
  end

  describe '#sync' do
    it 'calls #fetch' do
      expect(@tc).to receive(:fetch)
      @tc.sync
    end

    it 'returns nil if tasklists_json is nil' do
      allow(@tc).to receive(:fetch).and_return(nil)
      expect(@tc.sync).to eq nil
    end

    it 'returns tasklists_json if tasklists_json has errors' do
      allow(@tc).to receive(:fetch).and_return(@error_response)
      expect(@tc.sync).to eq @error_response
    end

    it 'calls handle_tasklist' do
      allow(@tc).to receive(:fetch).and_return(@good_response)
      allow(@tc).to receive(:handle_tasklist).and_return(1)
      allow(@tc).to receive(:fetch_default).and_return(@default_response)
      allow(Tasklist).to receive(:where).and_return(true)

      expect(@tc).to receive(:handle_tasklist)
      @tc.sync
    end

    it 'calls where on Tasklist' do
      allow(@tc).to receive(:fetch).and_return(@good_response)
      allow(@tc).to receive(:fetch_default).and_return(@default_response)
      allow(@tc).to receive(:handle_tasklist).and_return(1)

      expect(Tasklist).to receive(:where).once
      @tc.sync
    end
  end

  describe '#sync_default' do
    it 'calls #fetch_default' do
      expect(@tc).to receive(:fetch_default)
      @tc.sync_default
    end

    it 'returns if default_tasklist_json is nil' do
      allow(@tc).to receive(:fetch_default).and_return(nil)
      expect(@tc.sync_default).to eq nil
    end

    it 'returns if default_tasklist_json has errors' do
      allow(@tc).to receive(:fetch_default).and_return(@error_response)

      expect(@tc.sync_default).to eq @error_response
    end

    it 'calls handle_tasklist' do
      allow(@tc).to receive(:fetch_default).and_return(@default_response)
      allow(@tc).to receive(:handle_tasklist).and_return(1)
      allow(Tasklist).to receive(:find).and_return(true)

      expect(@tc).to receive(:handle_tasklist)
      @tc.sync_default
    end

    it 'calls find on Tasklist' do
      allow(@tc).to receive(:fetch_default).and_return(@default_response)
      allow(@tc).to receive(:handle_tasklist).and_return(1)

      expect(Tasklist).to receive(:find).once
      @tc.sync_default
    end
  end

  describe '#update_property' do
    it 'updates a property' do
      allow(@property).to receive(:reload).and_return(@property)

      expect(@property).to receive(:reload)
      @tc.update_property(@property, 'title')
    end
  end
end
