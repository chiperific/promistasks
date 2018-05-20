# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaskClient, type: :service do
  let(:user) { create :oauth_user }
  let(:tasklist) { create :property}
  stub_request(:any, 'https://www.googleapis.com/tasks/v1/lists/' )

  describe '#list' do
    pending 'returns all tasks in the specified tasklist'
  end
end
