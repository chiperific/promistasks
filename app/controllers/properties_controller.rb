# frozen_string_literal: true

class PropertiesController < ApplicationController
  def index
    authorize @properties = Property.where(is_default: false).visible_to(current_user)
  end

  def list
    authorize @properties = Property.where(is_default: false).visible_to(current_user)
  end

  def show
    authorize @property = Property.find(params[:id])

    occupancy = @property.connections.where(relationship: 'tennant').order(stage_date: :desc)

    if occupancy.empty?
      @occupancy_msg = 'Not recorded'
    else
      @occupancy_msg = occupancy.first.user.name + ' ' +
                       occupancy.first.stage + ' on ' +
                       human_date(occupancy.first.stage_date)
    end

    @connections = @property.connections

    @primary_info_hash = {
      'Occupancy status': @occupancy_msg,
      'Lot rent': @property.lot_rent || 'Not recorded',
      'Acquired on': human_date(@property.acquired_on) || 'Not recorded',
      'Creator': @property.creator.name
    }

    @secondary_info_hash = {
      'Certificate #': @property.certificate_number.present? ? @property.certificate_number : 'Not recorded',
      'Cost': @property.cost.present? ? @property.cost.format : 'Not recorded',
      'Created on': human_date(@property.created_at),
      'Created in': @property.created_from_api? ? 'Google Tasks' : 'PromiseTasks',
      'Year manufactured': @property.year_manufacture || 'Not recorded',
      'Manufacturer': @property.manufacturer.present? ? @property.manufacturer : 'Not recorded',
      'Serial #': @property.serial_number.present? ? @property.serial_number : 'Not recorded'
    }

    @tasks = @property.tasks.in_process.visible_to(current_user)
  end

  def new
    authorize @property = Property.new
  end

  def create
    modified_params = property_params.except :archive
    authorize @property = Property.new(modified_params)

    if @property.save
      redirect_to @return_path, notice: 'Property created'
    else
      flash[:warning] = 'Oops, found some errors'
      render 'new'
    end
  end

  def edit
    authorize @property = Property.find(params[:id])
  end

  def update
    authorize @property = Property.find(params[:id])
    @property.discard if property_params[:archive] == '1'
    modified_params = property_params.except :archive

    if @property.update(modified_params)
      redirect_to @return_path, notice: 'Property updated'
    else
      flash[:warning] = 'Oops, found some errors'
      render 'edit'
    end
  end

  def destroy
    authorize @property = Property.find(params[:id])
    authorize @property.discard
    redirect_to @return_path, notice: 'Property discarded'
  end

  def default
    authorize @property = Property.where(is_default: true, creator: current_user)
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

  def tasks_filter
    # from Property#show, ajax to update views/tasks/_tasks_table partial
    authorize @property = Property.find(params[:id])

    case params[:tasks]
    when nil || 'your'
      @tasks = @property.tasks.in_process.visible_to(current_user)
      @empty_msg = 'No active tasks'
    when 'all'
      @tasks = @property.tasks.active
      @empty_msg = 'No active tasks'
    when 'completed'
      @tasks = @property.tasks.complete
      @empty_msg = 'No completed tasks'
    when 'archived'
      @tasks = @property.tasks.visible_to(current_user).archived
      @empty_msg = 'No archived tasks'
    end

    respond_to do |format|
      format.js
    end
  end

  def property_enum
    authorize properties = Property.active.where(is_default: false).select(:name)

    hsh = {}
    properties.each do |property|
      hsh[property.name] = nil
    end
    render json: hsh
  end

  def find_id_by_name
    authorize current_user
    properties = Property.where(name: params[:name])

    property_id = properties.present? ? properties.first.id : 0

    render json: property_id
  end

  private

  def property_params
    params.require(:property).permit(:name, :address, :city, :state, :postal_code,
                                     :description, :acquired_on, :cost, :lot_rent, :budget,
                                     :certificate_number, :serial_number, :year_manufacture,
                                     :manufacturer, :bed_bath, :certification_label1, :certification_label2,
                                     :creator_id, :is_private, :ignore_budget_warning, :archive)
  end
end
