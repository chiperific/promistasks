# frozen_string_literal: true

class ParkUsersController < ApplicationController
  before_action :set_park_user, only: %i[edit update destroy]

  def index
    authorize ParkUser

    @park_users = ParkUser.all
  end

  def new
    authorize @park_user = ParkUser.new

    @park_user.user = User.find(params[:user]) if params[:user].present?
    @park_user.park = Park.find(params[:park]) if params[:park].present?
    @park_user.relationship = params[:relationship] if params[:relationship].present?
  end

  def create
    authorize @park_user = ParkUser.new(park_user_params)

    if @park_user.save
      redirect_to @return_path, notice: 'Connection created'
    else
      flash[:warning] = 'Oops, found some errors'
      render 'new'
    end
  end

  def edit
    authorize @park_user
  end

  def update
    authorize @park_user

    if @park_user.update(park_user_params)
      redirect_to @return_path, notice: 'Update successful'
    else
      flash[:warning] = 'Oops, found some errors'
      render 'edit'
    end
  end

  def destroy
    authorize @park_user

    @park_user.destroy
    redirect_to @return_path, notice: 'Connection deleted'
  end

  private

  def set_park_user
    @park_user = ParkUser.find(params[:id])
  end

  def park_user_params
    params.require(:park_user).permit(:park_id, :user_id, :relationship)
  end
end
