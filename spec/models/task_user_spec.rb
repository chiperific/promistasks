# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaskUser, type: :model do
  before :each do
    User.destroy_all
    Property.destroy_all
    Tasklist.destroy_all
    TaskUser.destroy_all
    stub_request(:any, Constant::Regex::TASKLIST).to_return(
      { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:tasklist_json).marshal_dump.to_json },
      { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:tasklist_json).marshal_dump.to_json },
      { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:tasklist_json).marshal_dump.to_json },
      { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:tasklist_json).marshal_dump.to_json }
    )
    stub_request(:any, Constant::Regex::TASK).to_return(
      { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:task_json).marshal_dump.to_json },
      { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:task_json).marshal_dump.to_json },
      { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:task_json).marshal_dump.to_json },
      { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:task_json).marshal_dump.to_json }
    )
    @task = FactoryBot.create(:task)
    @user = FactoryBot.create(:oauth_user)
    @task_user = FactoryBot.create(:task_user, task: @task, user: @user)
    WebMock::RequestRegistry.instance.reset!
  end
  describe 'must be valid' do
    pending 'in order to save'
  end

  describe 'requires uniqueness' do
    pending 'on task and user'
    pending 'on google_id'
  end

  describe '#set_position_as_integer' do
    let(:has_position) { build :task_user, task: @task, position: '0000001234'}

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

  describe '#set_tasklist_id' do
    pending 'only fires if tasklist_id is empty'
    pending 'sets the tasklist_id from the parent property'
  end
end