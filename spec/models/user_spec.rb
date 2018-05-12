# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { build :user }

  describe 'must be valid against schema' do
    it 'in order to save' do
    end
  end

  describe 'must be valid against model' do
    it 'in order to save' do
    end
  end

  describe 'requires uniqueness' do
  end

  describe 'requires booleans be in a state:' do
  end
end
