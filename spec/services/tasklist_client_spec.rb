# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TasklistClient, type: :service do
  let(:user) { create :oauth_user }
  let(:tasklist) { create :property}

  describe '#list' do
    pending 'returns all tasks in the specified tasklist'
      # stub_request(:get, 'https://www.googleapis.com/tasks/v1/users/@me/lists').
      #   with(headers: { 'Authorization' => /OAuth .{129}/, 'Content-type' => 'application/json' })
  end

  describe '#get' do
    pending 'returns a task'
      # stub_request(:get, /https:\/\/www.googleapis.com\/tasks\/v1\/users\/@me\/lists\/\w{32}/).
      #   with(headers: { 'Authorization' => /OAuth .{129}/, 'Content-type' => 'application/json' })
  end

  describe '#insert' do
    pending 'adds a new task'
      # stub_request(:post, 'https://www.googleapis.com/tasks/v1/users/@me/lists').
      #   with(headers: { 'Authorization' => /OAuth .{129}/, 'Content-type' => 'application/json' })
  end

  describe '#update' do
    pending 'updates a task'
      # stub_request(:patch, /https:\/\/www.googleapis.com\/tasks\/v1\/users\/@me\/lists\/\w{32}/).
      #   with(headers: { 'Authorization' => /OAuth .{129}/, 'Content-type' => 'application/json' })
  end

  describe '#delete' do
    pending 'removes a task'
      # stub_request(:delete, /https:\/\/www.googleapis.com\/tasks\/v1\/users\/@me\/lists\/\w{32}/).
      #   with(headers: { 'Authorization' => /OAuth .{129}/, 'Content-type' => 'application/json' })
  end
end
