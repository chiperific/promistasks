# frozen_string_literal: true

class PropertiesController < ApplicationController
  def index
    # my_properties = policy_scope(Property)
    @properties = Property.visible_to(current_user)
    @syncing = params[:syncing] == 'true' ? 'show' : 'hide'
    @job = current_user.jobs.where(completed_at: nil).last
  end

  def show
    @property = Property.find(params[:id])
  end

  def new
    @property = Property.new
  end

  def create
    @property = Property.find(params[:id])
  end

  def edit
    @property = Property.find(params[:id])
  end

  def update
    @property = Property.find(params[:id])
  end

  def destroy
    @property = Property.find(params[:id])
    @property.discard
    redirect_to properties_url, notice: 'Property discarded'
  end

  def discarded
    @properties = Property.discarded
  end
end
