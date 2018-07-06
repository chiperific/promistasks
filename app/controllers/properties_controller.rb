# frozen_string_literal: true

class PropertiesController < ApplicationController
  def index
    authorize @properties = Property.where(is_default: false).visible_to(current_user)
  end

  def show
    authorize @property = Property.find(params[:id])
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
      render 'edit'
    end
  end

  def edit
    authorize @property = Property.find(params[:id])
  end

  def update
    authorize @property = Property.find(params[:id])
    @property.discard if property_params[:archive].present?
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
    authorize @property = Property.where(is_default: true, creator: current_user).first
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

  private

  def property_params
    params.require(:property).permit(:name, :address, :city, :state, :postal_code,
                                     :description, :acquired_on, :cost, :lot_rent, :budget,
                                     :certificate_number, :serial_number, :year_manufacture,
                                     :manufacturer, :model, :certification_label1, :certification_label2,
                                     :creator, :is_private, :ignore_budget_warning, :archive)
  end
end
