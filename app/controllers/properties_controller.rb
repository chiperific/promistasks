# frozen_string_literal: true

class PropertiesController < ApplicationController
  def index
    # my_properties = policy_scope(Property)
    authorize @properties = Property.visible_to(current_user)
    job = current_user.jobs.where(completed_at: nil).last
    @job_id = job&.id || 0
  end

  def show
    authorize @property = Property.find(params[:id])
  end

  def new
    authorize @property = Property.new
  end

  def create
    authorize @property = Property.find(params[:id])
  end

  def edit
    authorize @property = Property.find(params[:id])
  end

  def update
    authorize @property = Property.find(params[:id])
  end

  def destroy
    authorize @property = Property.find(params[:id])
    authorize @property.discard
    redirect_to properties_url, notice: 'Property discarded'
  end

  def reports
    authorize @properties = Property.undiscarded
    @discarded_properties = Property.discarded

    # reports include:
    # budget status per property
    # properties by connection.stage
  end

  def discarded
    authorize @properties = Property.discarded
  end
end
