# frozen_string_literal: true

class ParksController < ApplicationController
  before_action :set_park, only: %i[show edit update destroy user properties_filter]

  def index
    authorize Park
    @parks = Park.undiscarded.order(:name)
  end

  def list
    authorize Park
    parks = Park.all.order(:name)
    @show_new = parks.created_since(current_user.last_sign_in_at).count.positive?

    # binding.pry

    @colspan = Constant::Property::STAGES.count + 4

    case params[:filter]
    when 'new'
      @parks = parks.created_since(current_user.last_sign_in_at)
      @empty_msg = 'No new parks'
    when 'archived'
      @parks = parks.discarded
      @empty_msg = 'No archived parks'
    else # 'active'
      @parks = parks.undiscarded
      @empty_msg = 'No parks found'
    end

    respond_to do |format|
      format.js
      format.html
    end
  end

  def show
    authorize @park

    @primary_info_hash = {
      'Address': @park.full_address.present? ? @park.full_address : 'Not recorded',
      'Point of Contact': @park.poc_name.present? ? @park.poc_name : 'Not recorded',
      'POC Email': @park.poc_email.present? ? @park.poc_email : 'Not recorded',
      'POC Phone': @park.poc_phone.present? ? @park.poc_phone : 'Not recorded'
    }

    @properties = @park.properties.related_to(current_user)
    @payments = @park.payments.undiscarded.order(:due)
    @connections = @park.park_users
  end

  def new
    authorize @park = Park.new
  end

  def edit
    authorize @park
  end

  def create
    authorize @park = Park.new(park_params)

    if @park.save
      redirect_to @return_path, notice: 'Park was successfully created.'
    else
      flash[:warning] = 'Oops, found some errors'
      render 'new'
    end
  end

  def update
    authorize @park

    @park.discard if params[:park][:archived] == '1' && !@park.discarded?
    @park.undiscard if params[:park][:archived] == '0' && @park.discarded?

    if @park.update(park_params)
      redirect_to @return_path, notice: 'Park updated'
    else
      flash[:warning] = 'Oops, found some errors'
      render 'edit'
    end
  end

  def properties_filter
    authorize @park
    properties = @park.properties.related_to(current_user)

    @show_new = properties.created_since(current_user.last_sign_in_at).count.positive?

    case params[:properties]
    when 'new'
      @properties = properties.created_since(current_user.last_sign_in_at)
      @empty_msg = 'No properties created since you last signed in'
    when 'vacant'
      @properties = @park.properties.vacant
      @empty_msg = 'No vacant properties'
    when 'pending'
      @properties = @park.properties.pending
      @empty_msg = 'No properties with pending applications'
    when 'approved'
      @properties = @park.properties.approved
      @empty_msg = 'No properties with approved applicants'
    when 'occupied'
      @properties = @park.properties.occupied
      @empty_msg = 'No occupied properties'
    when 'tasks'
      @properties = @park.properties.except_default.with_tasks_for(current_user)
      @empty_msg = 'No properties with tasks for you'
    when 'over'
      @properties = properties.over_budget
      @empty_msg = 'No properties over budget!'
    when 'near'
      @properties = properties.nearing_budget
      @empty_msg = 'No properties within $500 of budget!'
    when 'title'
      @properties = properties.needs_title
      @empty_msg = 'No properties missing titles'
    when 'admin'
      @properties = @park.properties.except_default
      @empty_msg = 'No properties in system'
    when 'all'
      @properties = @park.properties.visible_to(current_user)
      @empty_msg = 'No properties visible to you'
    else # 'yours' || nil
      @properties = properties
      @empty_msg = 'No properties related to you'
    end

    respond_to do |format|
      format.js
      format.html
    end
  end

  def properties
    @park = Park.find(params[:id])

    @associated_properties = @park.properties.active

    @other_properties = Property.active.where.not(park_id: @park.id)
  end

  def update_properties
  end

  private

  def set_park
    @park = Park.find(params[:id])
  end

  def park_params
    params.require(:park).permit(:name, :address, :city, :state, :postal_code,
                                 :notes, :poc_name, :poc_email, :poc_phone)
  end
end
