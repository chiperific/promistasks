# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TasklistClient, type: :service do
  let(:user) { create :oauth_user }
  let(:tasklist) { create :property}
  # list
  stub_request(:get, 'https://www.googleapis.com/tasks/v1/users/@me/lists').
    with(headers: { 'Authorization' => /OAuth .{129}/, 'Content-type' => 'application/json' })
  # get
  stub_request(:get, /https:\/\/www.googleapis.com\/tasks\/v1\/users\/@me\/lists\/\w{32}/).
    with(headers: { 'Authorization' => /OAuth .{129}/, 'Content-type' => 'application/json' })
  # insert
  stub_request(:post, 'https://www.googleapis.com/tasks/v1/users/@me/lists').
    with(headers: { 'Authorization' => /OAuth .{129}/, 'Content-type' => 'application/json' })
  # update
  stub_request(:patch, /https:\/\/www.googleapis.com\/tasks\/v1\/users\/@me\/lists\/\w{32}/).
    with(headers: { 'Authorization' => /OAuth .{129}/, 'Content-type' => 'application/json' })
  # delete
  stub_request(:delete, /https:\/\/www.googleapis.com\/tasks\/v1\/users\/@me\/lists\/\w{32}/).
    with(headers: { 'Authorization' => /OAuth .{129}/, 'Content-type' => 'application/json' })

  describe '#list' do
    pending 'returns all tasks in the specified tasklist'
  end
end
