# frozen_string_literal: true

class PropertiesController < ApplicationController
  def index
    authorize Property
    @properties = Property.except_default.visible_to(current_user)
  end

  def list
    authorize Property
    properties = Property.except_default.related_to(current_user)

    @show_new = properties.created_since(current_user.last_sign_in_at).count.positive?

    case params[:filter]
    when 'new'
      @properties = properties.created_since(current_user.last_sign_in_at)
      @empty_msg = 'No properties created since you last signed in'
    when 'vacant'
      @properties = Property.vacant
      @empty_msg = 'No vacant properties'
    when 'pending'
      @properties = Property.pending
      @empty_msg = 'No properties with pending applications'
    when 'approved'
      @properties = Property.approved
      @empty_msg = 'No properties with approved applicants'
    when 'occupied'
      @properties = Property.occupied
      @empty_msg = 'No occupied properties'
    when 'tasks'
      @properties = Property.except_default.with_tasks_for(current_user)
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
      @properties = Property.except_default
      @empty_msg = 'No properties in system'
    when 'all'
      @properties = Property.except_default.visible_to(current_user)
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

  def show
    authorize @property = Property.find(params[:id])

    @connections = @property.connections.except_tennants
    @occupancies = @property.connections.only_tennants

    @creator_name = current_user.staff_or_admin? ? view_context.link_to(@property.creator.name, @property.creator) : @property.creator.name

    @park_name = if @property.park.present?
                   current_user.staff_or_admin? ? view_context.link_to(@property.park.name, @property.park) : @property.park.name
                 else
                   'Not associated'
                 end

    @primary_info_hash = {
      'Creator': @creator_name,
      'Park': @park_name,
      'Stage': @property.stage.capitalize,
      'Occupancy status': @property.occupancy_details,
      'Lot rent': human_money(@property.lot_rent) || 'Not recorded',
      'Acquired on': human_date(@property.acquired_on) || 'Not recorded',
      'Beds / Baths': @property.beds.to_s + ' / ' + @property.baths.to_s
    }

    @primary_info_hash = { 'Default tasklist for:': @primary_info_hash.first[1] } if @property.is_default

    @money_hash = {
      'Budget': human_money(@property.budget) || 'Not recorded',
      'ALL COSTS TO DATE:': human_money(@property.cost_to_date) || 'Not recorded',
      '- Purchase Cost': @property.cost.present? ? @property.cost.format : 'Not recorded',
      '- Cost of tasks': @property.cost_of_tasks.format,
      '- Cost of payments': @property.cost_of_payments.format,
      '- Lot rent': @property.lot_rent.present? ? @property.lot_rent.format : 'Not recorded'
    }

    @secondary_info_hash = {
      'Expected Completion Date': @property.expected_completion_date.present? ? human_date(@property.expected_completion_date) : 'Not recorded',
      'Actual Completion Date': @property.actual_completion_date.present? ? human_date(@property.actual_completion_date) : 'Not recorded',
      'Certificate #': @property.certificate_number.present? ? @property.certificate_number : 'Not recorded',
      'Additional Cost': @property.additional_cost.present? ? @property.additional_cost.format : 'Not recorded',
      'Created on': human_date(@property.created_at),
      'Created in': @property.created_from_api? ? 'Google Tasks' : 'PromiseTasks',
      'Year manufactured': @property.year_manufacture || 'Not recorded',
      'Manufacturer': @property.manufacturer.present? ? @property.manufacturer : 'Not recorded',
      'Serial #': @property.serial_number.present? ? @property.serial_number : 'Not recorded'
    }

    @tasks = @property.tasks.in_process.visible_to(current_user)
    @show_new = @tasks.created_since(current_user.last_sign_in_at).visible_to(current_user).count.positive?

    @payments = @property.payments
  end

  def new
    authorize @property = Property.new

    @property.park_id = params[:park] if params[:park].present?
    @parks = Park.kept.order(:name).pluck(:name, :id)
  end

  def create
    authorize @property = Property.new(property_params)
    @property.creator_id = current_user.id

    if @property.save
      redirect_to @return_path, notice: 'Property created'
    else
      flash[:warning] = 'Oops, found some errors'
      @property.park_id = params[:park] if params[:park].present?
      @parks = Park.kept.order(:name).pluck(:name, :id)
      render 'new'
    end
  end

  def edit
    authorize @property = Property.find(params[:id])

    @property.park_id = params[:park] if params[:park].present?
    @parks = Park.kept.order(:name).pluck(:name, :id)
  end

  def update
    authorize @property = Property.find(params[:id])
    @property.discard if params[:property][:archive] == '1' && !@property.discarded?
    @property.undiscard if params[:property][:archive] == '0' && @property.discarded?

    if @property.update(property_params)
      redirect_to @return_path, notice: 'Property updated'
    else
      flash[:warning] = 'Oops, found some errors'
      @property.park_id = params[:park] if params[:park].present?
      @parks = Park.kept.order(:name).pluck(:name, :id)
      render 'edit'
    end
  end

  def default
    authorize Property
    @property = Property.where(is_default: true, creator: current_user).first

    if @property.present?
      redirect_to property_path(@property)
    else
      redirect_to @return_path, notice: 'No default tasklist found'
    end
  end

  def reports
    if params[:include_archived] == 'true'
      authorize @properties = Property.with_discarded.reportable
      @include_archived = true
    else
      authorize @properties = Property.undiscarded.reportable
      @include_archived = false
    end
  end

  def tasks_filter
    # from Property#show, ajax to update views/tasks/_tasks_table partial
    authorize @property = Property.find(params[:id])

    case params[:tasks]
    when 'new'
      @tasks = @property.tasks.created_since(current_user.last_sign_in_at).visible_to(current_user)
      @empty_msg = 'No new tasks'
    when 'completed'
      @tasks = @property.tasks.complete.visible_to(current_user)
      @empty_msg = 'No completed tasks'
    when 'all'
      @tasks = @property.tasks.active
      @empty_msg = 'No active tasks'
    when 'archived'
      @tasks = @property.tasks.archived
      @empty_msg = 'No archived tasks'
    else # nil || 'your'
      @tasks = @property.tasks.in_process.visible_to(current_user)
      @empty_msg = 'No active tasks'
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

  def reassign
    authorize @properties = Property.active.except_default.order(:name)

    @parks = Park.all.active.order(:name)
  end

  def reassign_to
    authorize @property = Property.find(params[:id])
    @park = Park.find(params[:park_id])

    if @property.update(park: @park)
      status = 'success'
    else
      status = 'failed'
    end

    render json: { property_id: @property.id.to_s, property_name: @property.name, park_name: @park.name, status: status }
  end

  def update_stage
    authorize @property = Property.find(params[:id])

    if @property.update(stage: params[:stage])
      render json: (@property.name + '\'s stage updated to ' + @property.stage).to_json
    else
      render json: @property.errors[:stage]
    end
  end

  private

  def property_params
    params.require(:property).permit(:name, :stage, :address, :city, :state, :postal_code,
                                     :description, :acquired_on, :cost, :lot_rent, :budget, :additional_cost,
                                     :certificate_number, :serial_number, :year_manufacture,
                                     :manufacturer, :beds, :baths, :certification_label1, :certification_label2,
                                     :park_id, :creator_id, :is_private, :ignore_budget_warning, :show_on_reports,
                                     :expected_completion_date, :actual_completion_date)
  end
end
