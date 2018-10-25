# frozen_string_literal: true

class UtilitiesController < ApplicationController
  before_action :set_utility, only: %i[show edit update]

  def index
    authorize @utilities = Utility.active.order(:name)
  end

  def show
    authorize @utility

    @payments = Payment.where(utility_id: @utility.id)
  end

  def new
    authorize @utility = Utility.new
  end

  def create
    authorize @utility = Utility.new(utility_params)

    if @utility.save
      redirect_to @return_path, notice: 'Utility created'
    else
      flash[:warning] = 'Oops, found some errors'
      render 'new'
    end
  end

  def edit
    authorize @utility
  end

  def update
    authorize @utility

    @utility.discard if params[:utility][:archived] == '1' && !@park.discarded?
    @utility.undiscard if params[:utility][:archived] == '0' && @park.discarded?

    if @utility.update(utility_params)
      redirect_to @return_path, notice: 'Utility updated'
    else
      flash[:warning] = 'Oops, found some errors'
      render 'edit'
    end
  end

  private

  def set_utility
    @utility = Utility.find(params[:id])
  end

  def utility_params
    params.require(:utility).permit(:name, :address, :city, :state, :postal_code,
                                 :notes, :poc_name, :poc_email, :poc_phone)
  end
end
