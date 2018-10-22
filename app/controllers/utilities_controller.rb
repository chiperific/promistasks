# frozen_string_literal: true

class UtilitiesController < ApplicationController
  before_action :set_utility, only: %i[show edit update]

  def index
    authorize @utilities = Utility.active.order(:name)
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
