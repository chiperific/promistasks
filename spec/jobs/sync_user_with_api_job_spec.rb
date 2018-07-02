require 'rails_helper'

RSpec.describe SyncUserWithApiJob, type: :job do
  pending "add some examples to (or delete) #{__FILE__}"
  # FROM: user_spec.rb
  # describe '#sync_with_api' do
  #   before :each do
  #     @oauth_user.save
  #     3.times { FactoryBot.create(:property, creator: @oauth_user) }
  #   end

  #   pending 'runs in the background'
  #     # @oauth_user.sync_with_api
  #     # expect(Delayed::Worker.new.work_off).to eq [1, 0]

  #   it 'returns false unless oauth_id is present' do
  #     @user.save
  #     expect(@user.sync_with_api).to eq false
  #   end

  #   it 'calls the TasklistClient' do
  #     expect(TasklistsClient).to receive(:sync)
  #     @oauth_user.sync_with_api
  #   end

  #   it 'calls the TasksClient' do
  #     TasklistsClient.sync(@oauth_user)
  #     count = Property.visible_to(@oauth_user).count

  #     expect(TasksClient).to receive(:sync).exactly(count).times
  #     @oauth_user.sync_with_api
  #   end
  # end
end
