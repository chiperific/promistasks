# frozen_string_literal: true

require "rails_helper"

RSpec.describe ParkUsersController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(:get => "/park_users").to route_to("park_users#index")
    end

    it "routes to #new" do
      expect(:get => "/park_users/new").to route_to("park_users#new")
    end

    it "routes to #show" do
      expect(:get => "/park_users/1").to route_to("park_users#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/park_users/1/edit").to route_to("park_users#edit", :id => "1")
    end


    it "routes to #create" do
      expect(:post => "/park_users").to route_to("park_users#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/park_users/1").to route_to("park_users#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/park_users/1").to route_to("park_users#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/park_users/1").to route_to("park_users#destroy", :id => "1")
    end
  end
end
