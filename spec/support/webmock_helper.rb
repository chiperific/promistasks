# frozen_string_literal: true

module WebmockHelper
  RSpec.configure do |config|
    config.before(:each) do
      WebMock.stub_request(:post, 'https://accounts.google.com/o/oauth2/token').to_return(
        headers: { 'Content-Type' => 'application/json' },
        status: 200,
        body: FactoryBot.create(:user_json).marshal_dump.to_json
      )
      WebMock.stub_request(:any, Constant::Regex::TASK).to_return(
        headers: { 'Content-Type' => 'application/json' },
        status: 200,
        body: FactoryBot.create(:task_json).marshal_dump.to_json
      )
      WebMock.stub_request(:get, Constant::Regex::LIST_TASKS).to_return(
        headers: { 'Content-Type' => 'application/json' },
        status: 200,
        body: File.read(Rails.root.to_s + '/spec/fixtures/list_tasks_json_spec.json')
      )
      WebMock.stub_request(:any, Constant::Regex::TASKLIST).to_return(
        headers: { 'Content-Type' => 'application/json' },
        status: 200,
        body: FactoryBot.create(:tasklist_json).marshal_dump.to_json
      )
      WebMock.stub_request(:get, Constant::Regex::LIST_TASKLISTS).to_return(
        headers: { 'Content-Type' => 'application/json' },
        status: 200,
        body: File.read(Rails.root.to_s + '/spec/fixtures/list_tasklists_json_spec.json')
      )
      WebMock.stub_request(:get, Constant::Regex::DEFAULT_TASKLIST).to_return(
        headers: { 'Content-Type' => 'application/json' },
        status: 200,
        body: FactoryBot.create(:default_tasklist_json).marshal_dump.to_json
      )
      WebMock.stub_request(:get, Constant::Regex::STATIC_MAP).to_return(
        headers: { 'Content-Type' => 'image/png' },
        status: 200,
        body: 'http://localhost:300/assets/images/no_property.png'
      )
      WebMock.stub_request(:get, Constant::Regex::GEOCODE).to_return(
        headers: { 'Content-Type' => 'application/json' },
        status: 200,
        body: File.read(Rails.root.to_s + '/spec/fixtures/geocode_response_json_spec.json')
      )
    end
  end
end
