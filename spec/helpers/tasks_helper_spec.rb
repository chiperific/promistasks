# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TasksHelper, type: :helper do
  describe '#parse_completed_at(params)' do
    it 'overrides the value of :completed_at with a parsed time object' do
      @params = ActionController::Parameters.new("title": "Capture the Param!", "notes": "", "priority": "", "due": "Oct 22, 2018", "visibility": "0", "completed_at": "Oct 27, 2018", "creator_id": "1", "owner_id": "1", "subject_id": "0", "property_id": "1", "budget": "", "cost": "")
      @params.permit!

      expect(@params[:completed_at].is_a?(String)).to eq true

      expect(helper.parse_completed_at(@params)[:completed_at].is_a?(Time)).to eq true
    end
  end
end
