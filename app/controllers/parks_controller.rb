# frozen_string_literal: true

class ParksController < ApplicationController
  before_action :set_park, only: %i[show edit update destroy]

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
  end

  def new
    authorize @park = Park.new
  end

  def edit
    authorize @park
  end

  def create
    authorize Park
    @park = Park.new(park_params)
    if @park.save
      format.html { redirect_to @park, notice: 'Park was successfully created.' }
    else
      format.html { render :new }
    end
  end

  def update
    authorize @park
    if @park.update(park_params)
      format.html { redirect_to @park, notice: 'Park was successfully updated.' }
    else
      format.html { render :edit }
    end
  end

  private

  def set_park
    @park = Park.find(params[:id])
  end

  def park_params
    params.fetch(:park, {})
  end
end
