# frozen_string_literal: true

class PropertiesController < ApplicationController
  def index
    # my_properties = policy_scope(Property)
    @properties = Property.all
  end

  def show
  end

  def new
  end

  def create
  end

  def edit
  end

  def destroy
  end
end
